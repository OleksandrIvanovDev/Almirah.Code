# frozen_string_literal: true

require_relative 'base_document'

class Coverage < BaseDocument # rubocop:disable Style/Documentation
  attr_accessor :top_doc, :bottom_doc, :covered_items, :passed_steps_number, :failed_steps_number

  def initialize(top_doc)
    super()
    @top_doc = top_doc
    @bottom_doc = nil

    @id = "#{top_doc.id}-tests"
    @title = "Coverage Matrix: #{@id}"
    @covered_items = {}
    @passed_steps_number = 0
    @failed_steps_number = 0
  end

  def to_console
    puts "\e[35mTraceability: #{@id}\e[0m"
  end

  def to_html(nav_pane, output_file_path) # rubocop:disable Metrics/MethodLength
    html_rows = []

    html_rows.append('')
    s = "<h1>#{@title}</h1>\n"
    s += "<table class=\"controlled\">\n"
    s += "\t<thead> <th>#</th> <th style='font-weight: bold;'>#{@top_doc.title}</th> "
    s += "<th title='TestCaseId.TestStepId'>#</th> <th style='font-weight: bold;'>Test Step Description</th> "
    s += "<th style='font-weight: bold;'>Result</th> </thead>\n"
    html_rows.append s

    sorted_items = @top_doc.controlled_items.sort_by(&:id)

    sorted_items.each do |top_item|
      row = render_table_row top_item
      html_rows.append row
    end
    html_rows.append "</table>\n"

    save_html_to_file(html_rows, nav_pane, output_file_path)
  end

  def render_table_row(top_item) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    s = ''
    if top_item.coverage_links
      id_color = if top_item.coverage_links.length > 1
                   '' # "style='background-color: #fff8c5;'" # disabled for now
                 else
                   ''
                 end
      top_item.coverage_links.each do |bottom_item|
        s += "\t<tr>\n"
        s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
        s += "\t\t<td class=\"item_text\" style='width: 40%;'>#{top_item.text}</td>\n"

        test_step_color = case bottom_item.columns[-2].text.downcase
                          when 'pass'
                            @passed_steps_number += 1
                            "style='background-color: #cfc;'"
                          when 'fail'
                            @failed_steps_number += 1
                            "style='background-color: #fcc;'"
                          else
                            "style='background-color: #ffffee;'"
                          end
        test_step_result =  case bottom_item.columns[-2].text.downcase
                            when 'pass'
                              'PASS'
                            when 'fail'
                              'FAIL'
                            else
                              'N/A'
                            end

        s += "\t\t<td class=\"item_id\"><a href=\"./../../tests/protocols/#{bottom_item.parent_doc.id}/#{bottom_item.parent_doc.id}.html##{bottom_item.id}\" class=\"external\">#{bottom_item.id}</a></td>\n"
        s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{bottom_item.columns[1].text}</td>\n"
        s += "\t\t<td class=\"item_id\" #{test_step_color}>#{test_step_result}</td>\n"
        s += "\t</tr>\n"
        @covered_items[top_item.id.to_s.downcase] = top_item
      end
    else
      s += "\t<tr>\n"
      s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
      s += "\t\t<td class=\"item_text\" style='width: 40%;'>#{top_item.text}</td>\n"
      s += "\t\t<td class=\"item_id\"></td>\n"
      s += "\t\t<td class=\"item_text\" style='width: 42%;'></td>\n"
      s += "\t\t<td class=\"item_id\"></td>\n"
      s += "\t</tr>\n"
    end
    s
  end
end
