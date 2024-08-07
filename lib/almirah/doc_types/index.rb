# frozen_string_literal: true

require_relative 'base_document'

class Index < BaseDocument # rubocop:disable Metrics/ClassLength,Style/Documentation
  attr_accessor :project

  def initialize(project)
    super()
    @project = project
    @title = 'Document Index'
    @id = 'index'
  end

  def to_console
    puts "\e[36mIndex: #{@id}\e[0m"
  end

  def to_html(output_file_path) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    html_rows = []

    html_rows.append('')
    s = "<h1>#{@title}</h1>\n"

    # Specifications
    s = "<h2>Specifications</h2>\n"
    s += "<table class=\"controlled\">\n"
    s += "\t<thead>\n"
    s += "\t\t<th title=\"Document title\">Title</th>\n"
    s += "\t\t<th title=\"Number of Controlled Paragraphs\">Items</th>\n"
    s += "\t\t<th title=\"Number of Controlled Paragraphs with up-links\">Items<br>w/ Up-links</th>\n"
    s += "\t\t<th title=\"Number of references from other documents\">Items<br>w/ Down-links</th>\n"
    s += "\t\t<th title=\"Number of Controlled Paragraphs mentioned in Test Cases\">Covered <br>by Tests</th>\n"
    s += "\t\t<th title=\"Number of Controlled Paragraphs that have the same ID\">Duplicated<br>IDs</th>\n"
    s += "\t\t<th title=\"Number of Controlled Paragraphs that link to non-existing items\">Wrong<br>links</th>\n"
    s += "\t\t<th title=\"Number of 'TODO:' blocks in document\">TODOs</th>\n"
    s += "\t\t<th title=\"The last Controlled Paragraph sequence number (ID) used in the document\">Last Used<br>ID</th>\n"
    s += "</thead>\n"
    html_rows.append s

    sorted_items = @project.specifications.sort_by(&:id)

    sorted_items.each do |doc| # rubocop:disable Metrics/BlockLength
      s = "\t<tr>\n"
      s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"./specifications/#{doc.id}/#{doc.id}.html\" class=\"external\"><i class=\"fa fa-file-text-o\" style='background-color: ##{doc.color};'> </i>&nbsp#{doc.title}</a></td>\n"
      s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.controlled_items.length}</td>\n"
      s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.items_with_uplinks_number}</td>\n"
      s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.items_with_downlinks_number}</td>\n"
      s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.items_with_coverage_number}</td>\n"

      if doc.duplicated_ids_number.positive?
        s += "\t\t<td class=\"item_id\" style='width: 7%; background-color: #fcc;'>"
        s += "<div id=\"DL_#{doc.id}\" style=\"display: block;\">"
        s += "<a  href=\"#\" onclick=\"downlink_OnClick(this.parentElement); return false;\" class=\"external\" title=\"Number of Controlled Paragraphs that have the same ID\">#{doc.duplicated_ids_number}</a>"
        s += '</div>'
        s += "<div id=\"DLS_#{doc.id}\" style=\"display: none;\">"
        doc.duplicates_list.each do |lnk|
          s += "\t\t\t<a href=\"./specifications/#{doc.id}/#{doc.id}.html##{lnk.id}\" class=\"external\" title=\"Controlled Paragraph with duplicated ID\">#{lnk.id}</a>\n<br>"
        end
        s += '</div>'
        s += "</td>\n"
      else
        s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.duplicated_ids_number}</td>\n"
      end

      if !doc.wrong_links_hash.empty?
        s += "\t\t<td class=\"item_id\" style='width: 7%; background-color: #fcc;'>"
        s += "<div id=\"DL_#{doc.id}wl\" style=\"display: block;\">"
        s += "<a  href=\"#\" onclick=\"downlink_OnClick(this.parentElement); return false;\" class=\"external\" title=\"Number of Controlled Paragraphs that link to non-existing items\">#{doc.wrong_links_hash.length}</a>"
        s += '</div>'
        s += "<div id=\"DLS_#{doc.id}wl\" style=\"display: none;\">"
        doc.wrong_links_hash.each do |wrong_lnk, item|
          s += "\t\t\t<a href=\"./specifications/#{doc.id}/#{doc.id}.html##{item.id}\" class=\"external\" title=\"Controlled Paragraphs that link to non-existing items\">#{wrong_lnk}</a>\n<br>"
        end
        s += '</div>'
        s += "</td>\n"
      else
        s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.wrong_links_hash.length}</td>\n"
      end

      color = if !doc.todo_blocks.empty?
                'background-color: #fcc;'
              else
                ''
              end
      s += "\t\t<td class=\"item_id\" style='width: 7%; #{color}'>#{doc.todo_blocks.length}</td>\n"
      s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.last_used_id}</td>\n"
      s += "</tr>\n"
      html_rows.append s
    end
    html_rows.append "</table>\n"

    # Traceability Matrices
    s = "<h2>Traceability Matrices</h2>\n"
    s += "<table class=\"controlled\">\n"
    s += "\t<thead>\n"
    s += "\t\t<th title=\"Traceability Matrix Title\">Title</th>\n"
    s += "\t\t<th title=\"The ratio of Controlled Paragraphs mentioned in other documents and not-mentioned ones\">Coverage</th>\n"
    s += "\t\t<th title=\"Document, that contains Cotroled Paragraphs to be referenced in Bottom document(s)\">Top Document</th>\n"
    s += "\t\t<th title=\"Document(s), that contains references to Controlled Paragraphs from the Top Document\">Bottom Document</th>\n"
    s += "</thead>\n"
    html_rows.append s

    sorted_items = @project.traceability_matrices.sort_by(&:id)
    # buble-up design inputs
    design_inputs = []
    others = []
    sorted_items.each do |doc|
      if doc.bottom_doc
        others.append doc
      else
        design_inputs.append doc
      end
    end
    sorted_items = design_inputs + others

    sorted_items.each do |doc|
      s = "\t<tr>\n"
      coverage = doc.traced_items.length.to_f / doc.top_doc.controlled_items.length * 100.0
      s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"./specifications/#{doc.id}/#{doc.id}.html\" class=\"external\">#{doc.title}</a></td>\n"
      s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{'%.2f' % coverage}%</td>\n"
      s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'><i class=\"fa fa-file-text-o\" style='background-color: ##{doc.top_doc.color};'> </i>&nbsp#{doc.top_doc.title}</td>\n"
      if doc.bottom_doc
        s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'><i class=\"fa fa-file-text-o\" style='background-color: ##{doc.bottom_doc.color};'> </i>&nbsp#{doc.bottom_doc.title}</td>\n"
      else
        s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'><i class=\"fa fa-circle-o\"'> </i>&nbspAll References</td>\n"
      end
      s += "</tr>\n"
      html_rows.append s
    end
    html_rows.append "</table>\n"

    # Coverage Matrices
    unless @project.coverage_matrices.empty?
      s = "<h2>Coverage Matrices</h2>\n"
      s += "<table class=\"controlled\">\n"
      s += "\t<thead>\n"
      s += "\t\t<th>Title</th>\n"
      s += "\t\t<th title=\"The ratio of Controlled Paragraphs mentioned in test protocols and total number of Controlled Paragraphs\">Coverage</th>\n"
      s += "\t\t<th title=\"Numbers of passed and failed test steps\">Test Results</th>\n"
      s += "\t\t<th>Specification Covered</th>\n"
      s += "</thead>\n"
      html_rows.append s

      sorted_items = @project.coverage_matrices.sort_by(&:id)

      sorted_items.each do |doc|
        s = "\t<tr>\n"
        coverage = doc.covered_items.length.to_f / doc.top_doc.controlled_items.length * 100.0

        test_step_color = if doc.failed_steps_number.positive?
                            'background-color: #fcc;'
                          elsif !doc.failed_steps_number.positive? && doc.passed_steps_number.positive?
                            'background-color: #cfc;'
                          else
                            'background-color: #ffffee;'
                          end

        s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"./specifications/#{doc.id}/#{doc.id}.html\" class=\"external\">#{doc.title}</a></td>\n"
        s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{'%.2f' % coverage}%</td>\n" # rubocop:disable Style/FormatString
        s += "\t\t<td class=\"item_id\" style='width: 7%; #{test_step_color}' title='pass/fail'> #{doc.passed_steps_number}/#{doc.failed_steps_number} </td>\n"
        s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'>\
                    <i class=\"fa fa-file-text-o\" style='background-color: ##{doc.top_doc.color};'> </i>\
                    #{doc.top_doc.title}</td>\n"
        s += "</tr>\n"
        html_rows.append s
      end
      html_rows.append "</table>\n"
    end

    save_html_to_file(html_rows, nil, output_file_path)
  end
end
