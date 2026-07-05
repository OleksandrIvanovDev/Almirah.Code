# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

# Unit coverage for the per-row WorkItem dependency network (ADR-194): the graph
# built by Project#link_work_items over the ScopeTable WorkItems — intra-record
# step edges, activity-type-aligned cross-record resolution, the in-group /
# cross-group edge tag, per-row readiness, and the two violation gates.
#
# Like decision_groups_spec, the real linking runs in a `bundle exec ruby`
# subprocess: loading project.rb pulls in doc_types/coverage.rb whose top-level
# Coverage class collides with the stdlib Coverage module SimpleCov activates.
WORK_ITEMS_GEM_ROOT = File.expand_path('..', __dir__)

# Parses the decisions under <root>, builds the link registry and the work-item
# network, then writes the graph (keyed by canonical work-item id) as JSON.
WORK_ITEMS_RUNNER = <<~RUBY.freeze
  require '#{WORK_ITEMS_GEM_ROOT}/lib/almirah/project'
  require '#{WORK_ITEMS_GEM_ROOT}/lib/almirah/project_configuration'
  require 'json'
  root, out_file = ARGV
  project = Project.new(ProjectConfiguration.new(root))
  project.parse_decisions
  project.build_link_registry
  project.link_work_items
  graph = project.project_data.work_items.transform_values do |w|
    {
      'anchor' => w.row_anchor,
      'activity' => w.activity,
      'step' => w.step,
      'preds' => w.predecessors.map { |e| e.keys.first },
      'succs' => w.successors.map { |e| e.keys.first },
      'cross_group' => w.cross_group_predecessor_labels,
      'kitted' => w.fully_kitted?,
      'phase_violation' => w.phase_order_violation?,
      'cross_violation' => w.cross_record_violation?,
      'resolved' => w.resolved_dependencies.transform_values { |d| { 'anchor' => d[:anchor], 'label' => d[:label] } }
    }
  end
  File.write(out_file, JSON.generate(graph))
RUBY

RSpec.describe 'Work-item dependency network' do
  def write(root, rel_path, body)
    full = File.join(root, rel_path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, body)
  end

  def scope(title, header, *rows)
    "---\ntitle: \"#{title}\"\n---\n\n# Scope\n\n#{header}\n#{rows.join("\n")}\n"
  end

  def run_link(files)
    Dir.mktmpdir do |root|
      File.write(File.join(root, 'project.yml'), "specifications:\n  input: []\n")
      files.each { |rel, body| write(root, rel, body) }
      parse_in_subprocess(root)
    end
  end

  def parse_in_subprocess(root)
    runner = File.join(root, 'runner.rb')
    out_file = File.join(root, 'graph.json')
    File.write(runner, WORK_ITEMS_RUNNER)
    _out, err, status = Open3.capture3('bundle', 'exec', 'ruby', runner, root, out_file,
                                       chdir: WORK_ITEMS_GEM_ROOT)
    raise "runner failed: #{err}" unless status.success?

    JSON.parse(File.read(out_file))
  end

  # Standard Scope header with a leading # step column and a Depends On column.
  def step_header
    "| # | Item | Owner | Depends On | Status |\n|---|---|---|---|---|"
  end

  let(:graph) do
    run_link(
      'decisions/release a/adr-1-base.md' =>
        scope('ADR-1: Base', step_header,
              '| 1 | Analysis | BA |  | Done |',
              '| 2 | Code | DEV |  | In-Progress |'),
      'decisions/release a/adr-2-dep.md' =>
        scope('ADR-2: Dependent', step_header,
              '| 1 | Analysis | BA | >[ADR-1] | To Do |',
              '| 2 | Code | DEV | >[ADR-1] | To Do |'),
      'decisions/release b/adr-3-cross.md' =>
        scope('ADR-3: Cross group', step_header,
              '| 1 | Code | DEV | >[ADR-1] | In-Progress |'),
      'decisions/release b/adr-4-phase.md' =>
        scope('ADR-4: Phase order', step_header,
              '| 1 | Requirements | BA |  | To Do |',
              '| 2 | Code | DEV |  | In-Progress |'),
      'decisions/adr-8-tests.md' =>
        scope('ADR-8: Tests fallback', step_header,
              '| 1 | Tests | TEST | >[ADR-1] | To Do |'),
      'decisions/release b/adr-6-nostep.md' =>
        scope('ADR-6: No step column', "| Item | Owner | Status |\n|---|---|---|",
              '| Code | DEV | Done |'),
      'decisions/release b/adr-7-depnostep.md' =>
        scope('ADR-7: Depends on no-step', step_header,
              '| 1 | Code | DEV | >[ADR-6] | To Do |')
    )
  end

  it 'aligns a cross-record edge to the prerequisite row of the same activity type' do
    expect(graph['adr-2.1.Analysis']['preds']).to eq(['adr-1.1.Analysis'])
    # adr-2.2.Code also carries its intra-record step edge (adr-2.1.Analysis).
    expect(graph['adr-2.2.Code']['preds']).to include('adr-1.2.Code')
  end

  it 'fills intra-record predecessors from lower-numbered steps' do
    expect(graph['adr-1.2.Code']['preds']).to eq(['adr-1.1.Analysis'])
  end

  it 'populates inverse successor edges' do
    # adr-8.1.Tests resolves to adr-1.2.Code via the nearest-earlier-activity fallback.
    expect(graph['adr-1.2.Code']['succs']).to contain_exactly('adr-2.2.Code', 'adr-3.1.Code', 'adr-8.1.Tests')
  end

  it 'kits a row only when every predecessor is Done' do
    expect(graph['adr-2.1.Analysis']['kitted']).to be true   # adr-1.1.Analysis is Done
    expect(graph['adr-2.2.Code']['kitted']).to be false      # adr-1.2.Code is In-Progress
  end

  it 'tags a same-group edge in-group and a cross-group edge cross-group' do
    expect(graph['adr-2.2.Code']['cross_group']).to eq([])
    expect(graph['adr-3.1.Code']['cross_group']).to eq(['adr-1.2.Code'])
  end

  it 'flags a started row with an unfinished lower step as a phase-order violation' do
    expect(graph['adr-4.2.Code']['phase_violation']).to be true
    expect(graph['adr-4.1.Requirements']['phase_violation']).to be false
  end

  it 'flags a started row blocked by an unfinished cross-record predecessor' do
    expect(graph['adr-3.1.Code']['cross_violation']).to be true
  end

  it 'falls back to the nearest earlier activity when the exact type is absent' do
    expect(graph['adr-8.1.Tests']['preds']).to eq(['adr-1.2.Code'])
    expect(graph['adr-8.1.Tests']['resolved']['ADR-1']['label']).to eq('adr-1.2.Code')
  end

  it 'numbers a row by intrinsic order when the # column is absent' do
    expect(graph).to have_key('adr-6.1.Code')
    expect(graph['adr-6.1.Code']['step']).to eq(1)
  end

  it 'namespaces the Scope row anchor with .scope.' do
    expect(graph['adr-1.2.Code']['anchor']).to eq('adr-1.scope.2')
  end

  it 'records a deep-link anchor when the target has a # column' do
    expect(graph['adr-2.1.Analysis']['resolved']['ADR-1']['anchor']).to eq('adr-1.scope.1')
  end

  it 'omits the anchor when the target record has no # column' do
    expect(graph['adr-7.1.Code']['preds']).to eq(['adr-6.1.Code'])
    expect(graph['adr-7.1.Code']['resolved']['ADR-6']['anchor']).to be_nil
  end
end
