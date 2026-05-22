# frozen_string_literal: true

require 'json'
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

  def to_html(output_file_path) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
    html_rows = []
    html_rows.append('')
    html_rows.append "<h1>#{@title}</h1>\n"

    html_rows.append render_charts_grid

    html_rows.append "<table class=\"controlled decisions_overview\">\n"
    html_rows.append "\t<thead>\n"
    html_rows.append "\t\t<th>#</th>\n"
    html_rows.append "\t\t<th>Type</th>\n"
    html_rows.append "\t\t<th>Status</th>\n"
    html_rows.append "\t\t<th>Title</th>\n"
    html_rows.append "\t\t<th>Start Date</th>\n"
    html_rows.append "\t\t<th>Target Date</th>\n"
    html_rows.append "\t\t<th title=\"Target Release Version\">Release</th>\n"
    html_rows.append "\t\t<th>Owner</th>\n"
    html_rows.append "</thead>\n"

    sorted_items = @project.project_data.decisions.sort_by do |d|
      [d.sequence_number ? 0 : 1, d.sequence_number.to_i, d.id]
    end
    sorted_items.each do |doc|
      s = "\t<tr>\n"
      s += "\t\t<td class=\"item_id\">\n"
      label = doc.sequence_number || doc.id
      href = doc.html_rel_path ? "./#{doc.html_rel_path}" : "##{doc.id}"
      anchor_attrs = %(name="#{doc.id}" id="#{doc.id}" href="#{href}" title="Decision Record ID")
      s += "\t\t\t<a #{anchor_attrs}>#{label}</a>"
      s += "\t\t</td>\n"
      s += "\t\t<td class=\"item_type\">#{doc.record_type}</td>\n"
      s += "\t\t<td class=\"item_status\">#{doc.current_status}</td>\n"
      title_html = doc.html_rel_path ? %(<a href="./#{doc.html_rel_path}" class="external">#{doc.title}</a>) : doc.title
      s += "\t\t<td class=\"item_text\" style='padding: 5px;'>#{title_html}</td>\n"
      start_date_html = doc.start_date ? doc.start_date.strftime('%d-%m-%Y') : ''
      s += "\t\t<td class=\"item_meta\">#{start_date_html}</td>\n"
      s += "\t\t<td class=\"item_meta\"></td>\n"
      s += "\t\t<td class=\"item_meta\">#{doc.target_release_version}</td>\n"
      s += "\t\t<td class=\"item_meta\"></td>\n"
      s += "</tr>\n"
      html_rows.append s
    end
    html_rows.append "</table>\n"

    save_html_to_file(html_rows, nil, output_file_path)
  end

  private

  def render_charts_grid
    counts = @project.project_data.decisions.each_with_object(Hash.new(0)) do |item, cntr|
      cntr[item.record_type] += 1 if item.record_type
    end
    labels = counts.keys.sort
    data = labels.map { |k| counts[k] }

    <<~HTML
      <div class="decisions_overview_charts">
      \t<div class="chart_cell">
      \t\t<canvas id="decisions_type_pie"></canvas>
      \t\t<script>
      \t\t\tnew Chart(document.getElementById('decisions_type_pie'), {
      \t\t\t\ttype: 'pie',
      \t\t\t\tdata: {
      \t\t\t\t\tlabels: #{labels.to_json},
      \t\t\t\t\tdatasets: [{ label: 'Decision records', data: #{data.to_json} }]
      \t\t\t\t},
      \t\t\t\toptions: { plugins: { title: { display: true, text: 'Decision Records by Type' } } }
      \t\t\t});
      \t\t</script>
      \t</div>
      \t<div class="chart_cell"></div>
      \t<div class="chart_cell"></div>
      </div>
    HTML
  end
end
