# frozen_string_literal: true

require 'fileutils'
require_relative 'doc_fabric'
require_relative 'doc_items/work_item'
require_relative 'navigation_pane'
require_relative 'doc_types/traceability'
require_relative 'doc_types/index'
require_relative 'search/specifications_db'
require_relative 'project/doc_linker'
require_relative 'project_configuration'
require_relative 'project/project_data'
require_relative 'console_reporter'
require_relative 'relative_url'

class Project
  attr_accessor :index, :project, :configuration, :project_data

  def initialize(configuration)
    @configuration = configuration
    @project_data = ProjectData.new

    @index = nil
    @project = self
    FileUtils.remove_dir("#{@configuration.project_root_directory}/build", true)
    copy_resources
  end

  def copy_resources
    # scripts
    gem_root = File.expand_path './../..', File.dirname(__FILE__)
    src_folder = "#{gem_root}/lib/almirah/templates/scripts"
    dst_folder = "#{@configuration.project_root_directory}/build/scripts"
    FileUtils.mkdir_p(dst_folder)
    FileUtils.copy_entry(src_folder, dst_folder)
    # css
    src_folder = "#{gem_root}/lib/almirah/templates/css"
    dst_folder = "#{@configuration.project_root_directory}/build/css"
    FileUtils.mkdir_p(dst_folder)
    FileUtils.copy_entry(src_folder, dst_folder)
  end

  def specifications_and_protocols
    parse_all_specifications
    parse_all_protocols
    parse_all_source_files
    parse_decisions
    parse_risks
    link_all_specifications
    link_all_protocols
    link_all_source_files
    link_all_decisions
    check_wrong_specification_referenced
    build_link_registry
    link_work_items
    create_index
    render_all_specifications(@project_data.specifications)
    render_all_specifications(@project_data.traceability_matrices)
    render_all_specifications(@project_data.coverage_matrices)
    render_all_protocols
    render_all_source_files
    render_all_specifications(@project_data.implementation_matrices) # intentionally after source file rendering
    render_decisions_overview
    render_critical_chain_page
    render_all_decisions
    render_all_risk_records
    render_risk_registry_pages
    render_index
    create_search_data
    report_broken_links
    report_kit_violations
    report_rendered
  end

  def specifications_and_results(test_run)
    parse_all_specifications
    parse_test_run test_run
    parse_all_source_files
    parse_decisions
    parse_risks
    link_all_specifications
    link_all_protocols
    link_all_source_files
    link_all_decisions
    check_wrong_specification_referenced
    build_link_registry
    link_work_items
    create_index
    render_all_specifications(@project_data.specifications)
    render_all_specifications(@project_data.traceability_matrices)
    render_all_specifications(@project_data.coverage_matrices)
    render_all_protocols
    render_all_source_files
    render_all_specifications(@project_data.implementation_matrices) # intentionally after source file rendering
    render_decisions_overview
    render_critical_chain_page
    render_all_decisions
    render_all_risk_records
    render_risk_registry_pages
    render_index
    create_search_data
    report_broken_links
    report_kit_violations
    report_rendered
  end

  def report_rendered
    root = @configuration.project_root_directory
    base = root == Dir.pwd ? '.' : root
    ConsoleReporter.result('rendering HTML', File.join(base, 'build', 'index.html'))
  end

  # Reports cross-document links that could not be resolved (ADR-186, SRS-094),
  # naming the linking document. The build still completes.
  def report_broken_links
    broken = TextLine.broken_links
    return if broken.empty?

    ConsoleReporter.warn('broken links', broken.length)
    broken.each { |b| puts ConsoleReporter.warn_detail("  #{b[:document] || '?'}: #{b[:target]}") }
  end

  # Builds the per-row WorkItem dependency network (ADR-194): registers every
  # Scope-row work item, fills the intra-record step-order edges, then resolves
  # each Depends On reference globally (LinkRegistry) to the activity-type-aligned
  # work item of the target record, tagging each cross-record edge in-group or
  # cross-group against the decision_groups boundary (ADR-197). Unresolved
  # references are collected for report_kit_violations. Runs after
  # build_link_registry (so every record resolves) and before rendering (so the
  # overview Kit column is ready).
  def link_work_items
    @kit_unresolved = []
    @project_data.decisions.each do |d|
      d.scope_work_items.each { |wi| @project_data.work_items[wi.id] = wi }
    end
    link_intra_record_steps
    link_cross_record_dependencies
  end

  # Each row's lower-numbered same-record steps are its predecessors; equal step
  # numbers are concurrent (no edge). These edges are in-group by definition.
  def link_intra_record_steps
    @project_data.decisions.each do |d|
      items = d.scope_work_items
      items.each do |wi|
        items.each do |other|
          next if other.equal?(wi) || other.step >= wi.step

          wi.add_predecessor(other, cross_group: false)
          other.add_successor(wi)
        end
      end
    end
  end

  def link_cross_record_dependencies
    @project_data.decisions.each do |d|
      d.scope_work_items.each do |wi|
        wi.depends_on_refs.each { |ref| link_dependency(d, wi, ref) }
      end
    end
  end

  def link_dependency(record, work_item, ref)
    target = @project_data.link_registry.find_by_id(ref)
    unless target.is_a?(Decision)
      @kit_unresolved << { record: record.id, target: ref }
      return
    end
    prereq = aligned_work_item(target, work_item.activity)
    return if prereq.nil? || prereq.equal?(work_item)

    cross = decision_group_name(record) != decision_group_name(target)
    work_item.add_predecessor(prereq, cross_group: cross)
    prereq.add_successor(work_item)
    anchor = target.scope_table&.step_column? ? prereq.row_anchor : nil
    work_item.add_resolved_dependency(ref, target, anchor, prereq.id)
  end

  # The target record's work item whose activity (Item) matches `activity`,
  # falling back to the nearest earlier activity by canonical phase order, then
  # (when the target has only later activities) to its earliest row. nil only
  # when the target has no Scope rows.
  def aligned_work_item(target, activity)
    items = target.scope_work_items
    return nil if items.empty?

    exact = items.select { |t| t.activity == activity }.min_by(&:step)
    return exact if exact

    rank = WorkItem::ACTIVITY_ORDER.index(activity) || WorkItem::ACTIVITY_ORDER.length
    earlier = items.select { |t| t.activity_rank <= rank }
    return items.min_by { |t| [t.activity_rank, t.step] } if earlier.empty?

    earlier.min_by { |t| [-t.activity_rank, t.step] }
  end

  # The planning-group name (first-level decisions/ folder) a record belongs to,
  # read from the decision_groups collection (ADR-197).
  def decision_group_name(doc)
    group = @project_data.decision_groups.find { |g| g.values.first.include?(doc) }
    group&.keys&.first
  end

  # Reports the two kit gates and unresolved Depends On references (ADR-194), all
  # as non-failing console warnings alongside report_broken_links.
  def report_kit_violations
    @kit_unresolved ||= []
    phase = @project_data.work_items.each_value.select(&:phase_order_violation?)
    cross = @project_data.work_items.each_value.select(&:cross_record_violation?)
    total = phase.length + cross.length + @kit_unresolved.length
    return if total.zero?

    ConsoleReporter.warn('kit violations', total)
    phase.each do |wi|
      blocking = wi.intra_record_predecessors.reject(&:done?).map(&:id).join(', ')
      puts ConsoleReporter.warn_detail("  phase order: #{wi.id} started before #{blocking}")
    end
    cross.each do |wi|
      blocking = wi.cross_record_predecessors.reject(&:done?).map(&:id).join(', ')
      puts ConsoleReporter.warn_detail("  not kitted: #{wi.id} needs #{blocking}")
    end
    @kit_unresolved.each do |u|
      puts ConsoleReporter.warn_detail("  unresolved Depends On: #{u[:record]} -> #{u[:target]}")
    end
  end

  # Assigns each document its generated output path (relative to the build root)
  # and registers it for cross-document link resolution (ADR-186). Runs after all
  # documents are parsed and before any rendering, so link targets are known.
  def build_link_registry
    reg = @project_data.link_registry
    TextLine.link_registry = reg
    TextLine.reset_broken_links
    @project_data.specifications.each do |d|
      d.output_rel_path = "specifications/#{d.id}/#{d.id}.html"
      reg.register(d)
    end
    @project_data.protocols.each do |d|
      d.output_rel_path = "tests/protocols/#{d.id}/#{d.id}.html"
      reg.register(d)
    end
    @project_data.decisions.each do |d|
      d.output_rel_path = "decisions/#{d.html_rel_path}"
      reg.register(d)
    end
    @project_data.risk_records.each do |d|
      d.output_rel_path = "risks/#{d.html_rel_path}"
      reg.register(d)
    end
    @project_data.source_files.each do |d|
      rel = d.path.sub("#{d.root_path}/", '')
      d.output_rel_path = "source_files/#{d.repository}/#{rel}.html"
      reg.register(d)
    end
  end

  def parse_all_specifications
    path = @configuration.project_root_directory
    Dir.glob("#{path}/specifications/**/*.md").each do |f|
      doc = DocFabric.create_specification(f)
      @project_data.specifications.append(doc)
      @project_data.specifications_dictionary[doc.id.to_s.downcase] = doc
    end
    ConsoleReporter.count('parsing specifications', @project_data.specifications.length)
  end

  def parse_all_protocols
    path = @configuration.project_root_directory
    Dir.glob("#{path}/tests/protocols/**/*.md").each do |f|
      doc = DocFabric.create_protocol(f)
      @project_data.protocols.append(doc)
    end
    ConsoleReporter.count('parsing test protocols', @project_data.protocols.length)
  end

  def parse_all_source_files
    @configuration.get_repositories.each do |repos|
      # puts "Processing repository: #{repos['name']}, #{repos['path']}"
      next unless repos['path'] && Dir.exist?(repos['path'])

      file_path = repos['path']
      Dir.glob("#{repos['path']}/**/*.*").each do |f|
        next unless File.file?(f) && f.end_with?('.c', '.cpp', '.h', '.hpp', '.py', '.java', '.rb', '.js', '.ts', '.go',
                                                 '.rs')

        doc = DocFabric.create_source_file(file_path, f, repos['name'])
        # puts "Source file: #{doc.id}"
        @project_data.source_files.append(doc)
      end
    end
  end

  def parse_decisions
    path = @configuration.project_root_directory
    decisions_root = "#{path}/decisions"
    Dir.glob("#{decisions_root}/**/*.md").each do |f|
      doc = DocFabric.create_decision(f)
      rel_dir = File.dirname(f.sub("#{decisions_root}/", ''))
      doc.html_rel_path = rel_dir == '.' ? "#{doc.id}.html" : "#{rel_dir}/#{doc.id}.html"
      @project_data.decisions.append(doc)
      add_to_decision_group(doc, rel_dir)
    end
    BaseDocument.show_decisions_link = @project_data.decisions.any?
    ConsoleReporter.count('parsing decisions', @project_data.decisions.length)
  end

  # Add a decision record to its planning group, keyed on the first-level folder
  # under decisions/ (a record directly under decisions/ has rel_dir '.', kept as
  # its own '.' group rather than dropped). Groups are single-key hashes appended
  # in folder-encounter order; the matching one is reused. See ADR-197.
  def add_to_decision_group(doc, rel_dir)
    group_name = rel_dir.split('/').first
    group = @project_data.decision_groups.find { |g| g.key?(group_name) }
    if group.nil?
      @project_data.decision_groups.append({ group_name => [doc] })
    else
      group[group_name].append(doc)
    end
  end

  # Collect risk records (ADR-215): each first-level subfolder of risks/ is a
  # risk registry; a registry's overview.md is its preface, not a record. Files
  # directly under risks/ belong to no registry and are not collected.
  def parse_risks
    path = @configuration.project_root_directory
    risks_root = "#{path}/risks"
    Dir.glob("#{risks_root}/*/**/*.md").each do |f|
      if File.basename(f).downcase == 'overview.md'
        register_risk_preface(f, risks_root)
        next
      end

      doc = DocFabric.create_risk_record(f)
      rel_dir = File.dirname(f.sub("#{risks_root}/", ''))
      doc.registry = rel_dir.split('/').first
      doc.html_rel_path = "#{rel_dir}/#{doc.id}.html"
      @project_data.risk_records.append(doc)
      add_to_risk_registry(doc)
    end
    ConsoleReporter.count('parsing risk records', @project_data.risk_records.length)
    report_duplicate_risk_ids
  end

  # A registry's own overview.md is its preface (ADR-216), parsed like a record
  # for rendering but never collected. An overview.md nested deeper inside a
  # registry is neither a record nor a preface and is skipped entirely.
  def register_risk_preface(file, risks_root)
    rel_dir = File.dirname(file.sub("#{risks_root}/", ''))
    return unless rel_dir.index('/').nil?

    doc = DocFabric.create_risk_record(file)
    doc.registry = rel_dir
    doc.output_rel_path = "risks/#{rel_dir}/overview.html"
    @project_data.risk_registry_prefaces[rel_dir] = doc
  end

  # Add a risk record to its registry, keyed on the first-level folder under
  # risks/. Registries are single-key hashes appended in folder-encounter order,
  # mirroring add_to_decision_group.
  def add_to_risk_registry(doc)
    registry = @project_data.risk_registries.find { |g| g.key?(doc.registry) }
    if registry.nil?
      @project_data.risk_registries.append({ doc.registry => [doc] })
    else
      registry[doc.registry].append(doc)
    end
  end

  # Two risk records sharing one id would collide in the project-wide link
  # space; each registry is expected to use its own letter prefix (ADR-215).
  # Reported as a non-failing warning, like broken links.
  def report_duplicate_risk_ids
    duplicates = @project_data.risk_records.group_by(&:id).select { |_id, records| records.length > 1 }
    return if duplicates.empty?

    ConsoleReporter.warn('duplicated risk ids', duplicates.length)
    duplicates.each do |id, records|
      files = records.map { |r| r.path.sub("#{@configuration.project_root_directory}/", '') }.join(', ')
      puts ConsoleReporter.warn_detail("  #{id}: #{files}")
    end
  end

  def parse_test_run(test_run)
    path = @configuration.project_root_directory
    Dir.glob("#{path}/tests/runs/#{test_run}/**/*.md").each do |f|
      doc = DocFabric.create_protocol(f)
      @project_data.protocols.append(doc)
    end
  end

  def link_all_specifications
    comb_list = @project_data.specifications.combination(2)
    comb_list.each do |c|
      link_two_specifications(c[0], c[1])
      # puts "Link: #{c[0].id} - #{c[1].id}"
    end
    # separatelly create design inputs treceability
    @configuration.get_design_inputs.each do |i|
      next unless @project_data.specifications_dictionary.key? i.to_s.downcase

      document = @project_data.specifications_dictionary[i.to_s.downcase]
      if document
        doc = DocFabric.create_traceability_document(document, nil)
        @project_data.traceability_matrices.append doc
      end
    end
    ConsoleReporter.count('traceability matrices', @project_data.traceability_matrices.length)
  end

  def link_all_protocols
    @project_data.protocols.each do |p|
      @project_data.specifications.each do |s|
        if p.up_link_docs.key?(s.id.to_s)
          DocLinker.link_protocol_to_spec(p, s)
          @project_data.covered_specifications_dictionary[s.id.to_s] = s
        end
      end
    end
    # create coverage documents
    @project_data.covered_specifications_dictionary.each do |_key, value|
      doc = DocFabric.create_coverage_matrix(value)
      @project_data.coverage_matrices.append doc
    end
    ConsoleReporter.count('coverage matrices', @project_data.coverage_matrices.length)
  end

  def link_all_decisions
    number_of_links = 0
    @project_data.decisions.each do |d|
      @project_data.specifications.each do |s|
        next unless d.up_link_docs.key?(s.id.to_s)

        DocLinker.link_decision_to_spec(d, s)
        number_of_links += 1
      end
    end
    ConsoleReporter.count('decision links', number_of_links)
  end

  def link_all_source_files
    return unless DocLinker.link_all_source_files(@project_data)

    # create implementation documents
    @project_data.implemented_specifications_dictionary.each do |_key, value|
      doc = DocFabric.create_implementation_document(value)
      @project_data.implementation_matrices.append doc
    end
    ConsoleReporter.count('implementation matrices', @project_data.implementation_matrices.length)
  end

  def check_wrong_specification_referenced
    available_specification_ids = {}

    @project_data.specifications.each do |s|
      available_specification_ids[s.id.to_s.downcase] = s
    end

    @project_data.specifications.each do |s| # rubocop:disable Style/CombinableLoops
      s.up_link_docs.each do |key, _value|
        next if available_specification_ids.key?(key)

        # now key points to the doc_id that does not exist
        wrong_doc_id = key
        # find the item that reference to it
        s.controlled_items.each do |item|
          next if item.up_link_ids.nil?

          item.up_link_ids.each do |up_link_id|
            next unless tmp = /^([a-zA-Z]+)-\d+/.match(up_link_id) # SRS

            if tmp[1].downcase == wrong_doc_id
              # we got it finally!
              s.wrong_links_hash[up_link_id.to_s] = item
            end
          end
        end
      end
    end
  end

  def link_two_specifications(doc_a, doc_b)
    if doc_b.up_link_docs.key?(doc_a.id.to_s)
      top_document = doc_a
      bottom_document = doc_b
    elsif doc_a.up_link_docs.key?(doc_b.id.to_s)
      top_document = doc_b
      bottom_document = doc_a
    else
      return # no links
    end
    # puts "Link: #{doc_a.id} - #{doc_b.id}"
    bottom_document.controlled_items.each do |item|
      next unless item.up_link_ids

      item.up_link_ids.each do |up_lnk|
        if top_document.dictionary.key?(up_lnk.to_s)

          top_item = top_document.dictionary[up_lnk.to_s]

          unless top_item.down_links
            top_item.down_links = []
            top_document.items_with_downlinks_number += 1 # for statistics
          end
          top_item.down_links.append(item)
        elsif tmp = /^([a-zA-Z]+)-\d+/.match(up_lnk)
          # check if there is a non existing link with the right doc_id
          if tmp[1].downcase == top_document.id.downcase
            bottom_document.wrong_links_hash[up_lnk] = item
          end # SRS
        end
      end
    end
    # create treceability document
    doc = DocFabric.create_traceability_document(top_document, bottom_document)
    @project_data.traceability_matrices.append doc
  end

  def create_index
    @index = Index.new(@project)
  end

  def render_all_specifications(spec_list)
    path = @configuration.project_root_directory

    FileUtils.mkdir_p("#{path}/build/specifications")

    spec_list.each do |doc|
      img_src_dir = "#{path}/specifications/#{doc.id}/img"
      img_dst_dir = "#{path}/build/specifications/#{doc.id}/img"

      FileUtils.mkdir_p(img_dst_dir)

      FileUtils.copy_entry(img_src_dir, img_dst_dir) if File.directory?(img_src_dir)

      nav_pane = NavigationPane.new(doc)
      doc.to_html(nav_pane, "#{path}/build/specifications/")
    end
  end

  def render_all_protocols
    path = @configuration.project_root_directory

    FileUtils.mkdir_p("#{path}/build/tests/protocols")

    @project_data.protocols.each do |doc|
      img_src_dir = "#{path}/tests/protocols/#{doc.id}/img"
      img_dst_dir = "#{path}/build/tests/protocols/#{doc.id}/img"

      FileUtils.mkdir_p(img_dst_dir)

      FileUtils.copy_entry(img_src_dir, img_dst_dir) if File.directory?(img_src_dir)

      nav_pane = NavigationPane.new(doc)
      doc.to_html(nav_pane, "#{path}/build/tests/protocols/")
    end
  end

  def render_all_source_files
    path = @configuration.project_root_directory
    FileUtils.mkdir_p("#{path}/build/source_files")

    @project_data.source_files.each do |doc|
      doc.to_html("#{path}/build/source_files/")
    end
  end

  def render_index
    path = @configuration.project_root_directory

    doc = @index
    doc.to_html("#{path}/build/")
  end

  def render_decisions_overview
    return if @project_data.decisions.empty?

    path = @configuration.project_root_directory
    FileUtils.mkdir_p("#{path}/build/decisions")

    doc = DocFabric.create_decisions_overview(@project)
    doc.to_html("#{path}/build/decisions/")
  end

  def render_critical_chain_page
    return if @project_data.decisions.empty?

    path = @configuration.project_root_directory
    FileUtils.mkdir_p("#{path}/build/decisions")

    doc = DocFabric.create_critical_chain_page(@project)
    doc.to_html("#{path}/build/decisions/")
  end

  def render_all_decisions
    return if @project_data.decisions.empty?

    build_decisions_root = "#{@configuration.project_root_directory}/build/decisions"
    @project_data.decisions.each do |doc|
      out_dir_rel = File.dirname(doc.html_rel_path)
      out_dir = out_dir_rel == '.' ? build_decisions_root : "#{build_decisions_root}/#{out_dir_rel}"
      FileUtils.mkdir_p(out_dir)
      depth = 1 + (out_dir_rel == '.' ? 0 : out_dir_rel.split('/').size)
      doc.root_prefix = '../' * depth
      doc.specifications_path = "./#{doc.root_prefix}specifications/"
      doc.to_html(NavigationPane.new(doc), "#{out_dir}/")
    end
  end

  # Each registry renders to build/risks/<registry>/overview.html (ADR-216):
  # the rendered preface first, then the register table of the registry's
  # records, with the columns configured under the risks: root of project.yml
  # (implicit columns plus Status when unconfigured). A registry holding only
  # an overview.md still renders, with an empty table. Runs after
  # render_all_risk_records so every record carries its rendering paths.
  def render_risk_registry_pages
    registry_names = (@project_data.risk_registries.map { |g| g.keys.first } +
                      @project_data.risk_registry_prefaces.keys).uniq
    return if registry_names.empty?

    path = @configuration.project_root_directory
    registry_names.each do |name|
      records = @project_data.risk_registries.find { |g| g.key?(name) }&.fetch(name) || []
      preface = @project_data.risk_registry_prefaces[name]
      if preface
        preface.root_prefix = '../../'
        preface.specifications_path = "./#{preface.root_prefix}specifications/"
      end
      doc = DocFabric.create_risk_registry_page(name, records, preface, @configuration.get_risk_columns(name))
      out_dir = "#{path}/build/risks/#{name}"
      FileUtils.mkdir_p(out_dir)
      doc.to_html("#{out_dir}/")
    end
  end

  # Each risk record renders to its own page under build/risks/<registry>/,
  # with the navigation pane, exactly as decision records do (ADR-215).
  def render_all_risk_records
    return if @project_data.risk_records.empty?

    build_risks_root = "#{@configuration.project_root_directory}/build/risks"
    @project_data.risk_records.each do |doc|
      out_dir_rel = File.dirname(doc.html_rel_path)
      out_dir = "#{build_risks_root}/#{out_dir_rel}"
      FileUtils.mkdir_p(out_dir)
      depth = 1 + out_dir_rel.split('/').size
      doc.root_prefix = '../' * depth
      doc.specifications_path = "./#{doc.root_prefix}specifications/"
      doc.to_html(NavigationPane.new(doc), "#{out_dir}/")
    end
  end

  def create_search_data
    db = SpecificationsDb.new @project_data.specifications
    data_path = "#{@configuration.project_root_directory}/build/data"
    FileUtils.mkdir_p(data_path)
    db.save(data_path)
  end
end
