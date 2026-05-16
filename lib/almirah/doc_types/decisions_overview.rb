# frozen_string_literal: true

require_relative 'base_document'

class DecisionsOverview < BaseDocument # rubocop:disable Style/Documentation
  attr_accessor :project

  def initialize(project)
    super()
    @project = project
    @title = 'Decision Records Overview'
    @id = 'overview'
  end

  def to_console
    puts "\e[36mDecisions Overview: #{@id}\e[0m"
  end

  def to_html(output_file_path) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    html_rows = []
    html_rows.append('')
    html_rows.append "<h1>#{@title}</h1>\n"

    html_rows.append "<table class=\"controlled\">\n"
    html_rows.append "\t<thead>\n"
    html_rows.append "\t\t<th>ID</th>\n"
    html_rows.append "\t\t<th>Title</th>\n"
    html_rows.append "</thead>\n"

    sorted_items = @project.project_data.decisions.sort_by(&:id)
    sorted_items.each do |doc|
      s = "\t<tr>\n"
      s += "\t\t<td class=\"item_id\" style='width: 20%;'>#{doc.id}</td>\n"
      s += "\t\t<td class=\"item_text\" style='padding: 5px;'>#{doc.title}</td>\n"
      s += "</tr>\n"
      html_rows.append s
    end
    html_rows.append "</table>\n"

    save_html_to_file(html_rows, nil, output_file_path)
  end
end
