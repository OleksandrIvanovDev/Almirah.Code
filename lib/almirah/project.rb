# frozen_string_literal: true

require 'fileutils'
require_relative 'doc_fabric'
require_relative 'navigation_pane'
require_relative 'doc_types/traceability'
require_relative 'doc_types/index'
require_relative 'search/specifications_db'

class Project # rubocop:disable Metrics/ClassLength,Style/Documentation
  attr_accessor :specifications, :protocols, :traceability_matrices, :coverage_matrices, :specifications_dictionary,
                :index, :project, :configuration

  def initialize(configuration)
    @configuration = configuration
    @specifications = []
    @protocols = []
    @traceability_matrices = []
    @coverage_matrices = []
    @specifications_dictionary = {}
    @covered_specifications_dictionary = {}
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

  def specifications_and_protocols # rubocop:disable Metrics/MethodLength
    parse_all_specifications
    parse_all_protocols
    link_all_specifications
    link_all_protocols
    check_wrong_specification_referenced
    create_index
    render_all_specifications(@specifications)
    render_all_specifications(@traceability_matrices)
    render_all_specifications(@coverage_matrices)
    render_all_protocols
    render_index
    create_search_data
  end

  def specifications_and_results(test_run) # rubocop:disable Metrics/MethodLength
    parse_all_specifications
    parse_test_run test_run
    link_all_specifications
    link_all_protocols
    check_wrong_specification_referenced
    create_index
    render_all_specifications(@specifications)
    render_all_specifications(@traceability_matrices)
    render_all_specifications(@coverage_matrices)
    render_all_protocols
    render_index
    create_search_data
  end

  def parse_all_specifications
    path = @configuration.project_root_directory
    # do a lasy pass first to get the list of documents id
    Dir.glob("#{path}/specifications/**/*.md").each do |f|
      DocFabric.add_lazy_doc_id(f)
    end
    # parse documents in the second pass
    Dir.glob("#{path}/specifications/**/*.md").each do |f| # rubocop:disable Style/CombinableLoops
      doc = DocFabric.create_specification(f)
      @specifications.append(doc)
      @specifications_dictionary[doc.id.to_s.downcase] = doc
    end
  end

  def parse_all_protocols
    path = @configuration.project_root_directory
    Dir.glob("#{path}/tests/protocols/**/*.md").each do |f|
      doc = DocFabric.create_protocol(f)
      @protocols.append(doc)
    end
  end

  def parse_test_run(test_run)
    path = @configuration.project_root_directory
    Dir.glob("#{path}/tests/runs/#{test_run}/**/*.md").each do |f|
      doc = DocFabric.create_protocol(f)
      @protocols.append(doc)
    end
  end

  def link_all_specifications # rubocop:disable Metrics/MethodLength
    comb_list = @specifications.combination(2)
    comb_list.each do |c|
      link_two_specifications(c[0], c[1])
      # puts "Link: #{c[0].id} - #{c[1].id}"
    end
    # separatelly create design inputs treceability
    @configuration.get_design_inputs.each do |i|
      next unless @specifications_dictionary.key? i.to_s.downcase

      document = @specifications_dictionary[i.to_s.downcase]
      if document
        doc = DocFabric.create_traceability_document(document, nil)
        @traceability_matrices.append doc
      end
    end
  end

  def link_all_protocols # rubocop:disable Metrics/MethodLength
    @protocols.each do |p|
      @specifications.each do |s|
        if p.up_link_docs.key?(s.id.to_s)
          link_protocol_to_spec(p, s)
          @covered_specifications_dictionary[s.id.to_s] = s
        end
      end
    end
    # create coverage documents
    @covered_specifications_dictionary.each do |_key, value|
      doc = DocFabric.create_coverage_matrix(value)
      @coverage_matrices.append doc
    end
  end

  def check_wrong_specification_referenced # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    available_specification_ids = {}

    @specifications.each do |s|
      available_specification_ids[s.id.to_s.downcase] = s
    end

    @specifications.each do |s| # rubocop:disable Style/CombinableLoops
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

  def link_two_specifications(doc_a, doc_b) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
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
    @traceability_matrices.append doc
  end

  def link_protocol_to_spec(protocol, specification) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    top_document = specification
    bottom_document = protocol

    bottom_document.controlled_items.each do |item|
      next unless item.up_link_ids

      item.up_link_ids.each do |up_lnk|
        if top_document.dictionary.key?(up_lnk.to_s)

          top_item = top_document.dictionary[up_lnk.to_s]

          unless top_item.coverage_links
            top_item.coverage_links = []
            top_document.items_with_coverage_number += 1 # for statistics
          end
          top_item.coverage_links.append(item)
        elsif tmp = /^([a-zA-Z]+)-\d+/.match(up_lnk)
          # check if there is a non existing link with the right doc_id
          if tmp[1].downcase == top_document.id.downcase
            bottom_document.wrong_links_hash[up_lnk] = item
          end # SRS
        end
      end
    end
  end

  def create_index
    @index = Index.new(@project)
  end

  def render_all_specifications(spec_list) # rubocop:disable Metrics/MethodLength
    path = @configuration.project_root_directory

    FileUtils.mkdir_p("#{path}/build/specifications")

    spec_list.each do |doc|
      doc.to_console

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

    @protocols.each do |doc|
      img_src_dir = "#{path}/tests/protocols/#{doc.id}/img"
      img_dst_dir = "#{path}/build/tests/protocols/#{doc.id}/img"

      FileUtils.mkdir_p(img_dst_dir)

      FileUtils.copy_entry(img_src_dir, img_dst_dir) if File.directory?(img_src_dir)

      nav_pane = NavigationPane.new(doc)
      doc.to_html(nav_pane, "#{path}/build/tests/protocols/")
    end
  end

  def render_index
    path = @configuration.project_root_directory

    doc = @index
    doc.to_console

    doc.to_html("#{path}/build/")
  end

  def create_search_data
    db = SpecificationsDb.new @specifications
    data_path = "#{@configuration.project_root_directory}/build/data"
    FileUtils.mkdir_p(data_path)
    db.save(data_path)
  end
end
