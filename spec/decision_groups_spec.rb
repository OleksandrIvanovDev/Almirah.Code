# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

# Unit coverage for @project_data.decision_groups, the folder-keyed grouping of
# decision records populated in Project#parse_decisions (ADR-197).
#
# The real parse is exercised in a `bundle exec ruby` subprocess rather than
# in-process: loading project.rb pulls in doc_types/coverage.rb, whose top-level
# `Coverage` class collides with the stdlib `Coverage` module that SimpleCov
# (required by spec_helper) activates. This is the same reason the e2e suite runs
# the gem out-of-process via aruba. This spec therefore requires only stdlib in
# the SimpleCov-instrumented process and shells out for the gem work.
DECISION_GROUPS_GEM_ROOT = File.expand_path('..', __dir__)

# A ruby program that parses the decisions under <root> and writes the resulting
# decision_groups (plus identity/count cross-checks) as JSON to <out_file>.
DECISION_GROUPS_RUNNER = <<~RUBY.freeze
  require '#{DECISION_GROUPS_GEM_ROOT}/lib/almirah/project'
  require '#{DECISION_GROUPS_GEM_ROOT}/lib/almirah/project_configuration'
  require 'json'
  root, out_file = ARGV
  project = Project.new(ProjectConfiguration.new(root))
  project.parse_decisions
  data = project.project_data
  grouped = data.decision_groups.flat_map { |g| g.values.first }
  result = {
    'groups' => data.decision_groups.map { |g| k = g.keys.first; { 'key' => k, 'ids' => g[k].map(&:id) } },
    'identity_ok' => grouped.all? { |doc| data.decisions.any? { |d| d.equal?(doc) } },
    'grouped_count' => grouped.length,
    'decisions_count' => data.decisions.length
  }
  File.write(out_file, JSON.generate(result))
RUBY

RSpec.describe 'Decision group collection' do
  def write(root, rel_path, title)
    full = File.join(root, rel_path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, "---\ntitle: \"#{title}\"\n---\n\n## Context\n\nBody.\n")
  end

  # Build the fixture tree, run the real parse_decisions out-of-process, return
  # the parsed JSON result.
  def run_parse(decision_files)
    Dir.mktmpdir do |root|
      File.write(File.join(root, 'project.yml'), "specifications:\n  input: []\n")
      decision_files.each { |rel, title| write(root, rel, title) }
      parse_in_subprocess(root)
    end
  end

  def parse_in_subprocess(root)
    runner = File.join(root, 'runner.rb')
    out_file = File.join(root, 'result.json')
    File.write(runner, DECISION_GROUPS_RUNNER)
    _out, err, status = Open3.capture3('bundle', 'exec', 'ruby', runner, root, out_file,
                                       chdir: DECISION_GROUPS_GEM_ROOT)
    raise "runner failed: #{err}" unless status.success?

    JSON.parse(File.read(out_file))
  end

  let(:result) do
    run_parse(
      'decisions/adr-900-top.md' => 'ADR-900: Top',
      'decisions/release 0.4.0/adr-170-a.md' => 'ADR-170: A',
      'decisions/release 0.4.0/adr-171-b.md' => 'ADR-171: B',
      'decisions/release 0.4.1/adr-180-c.md' => 'ADR-180: C',
      'decisions/release 0.4.1/issues/issue-5-d.md' => 'ISSUE-5: D'
    )
  end

  def ids(name)
    entry = result['groups'].find { |g| g['key'] == name }
    entry ? entry['ids'] : nil
  end

  it 'groups each record under its first-level folder name' do
    expect(ids('release 0.4.0')).to contain_exactly('adr-170', 'adr-171')
  end

  it 'folds records in nested sub-folders into their first-level parent group' do
    expect(ids('release 0.4.1')).to contain_exactly('adr-180', 'issue-5')
  end

  it 'keeps a record placed directly under decisions/ in the "." group' do
    expect(ids('.')).to contain_exactly('adr-900')
  end

  it 'orders groups by folder-encounter order' do
    expect(result['groups'].map { |g| g['key'] }).to eq(['.', 'release 0.4.0', 'release 0.4.1'])
  end

  it 'holds the same Decision objects as @project_data.decisions' do
    expect(result['identity_ok']).to be true
    expect(result['grouped_count']).to eq(result['decisions_count'])
  end
end
