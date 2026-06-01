# frozen_string_literal: true

require 'date'
require 'json'
require_relative 'base_document'

class DecisionsOverview < BaseDocument # rubocop:disable Style/Documentation,Metrics/ClassLength
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

  CHART_PALETTE = [
    [54, 162, 235], [255, 99, 132], [255, 159, 64], [255, 205, 86],
    [75, 192, 192], [153, 102, 255], [201, 203, 207]
  ].freeze

  # Records with a missing or ambiguous current-status marker are surfaced under
  # this category as a data-quality indicator rather than being silently dropped.
  UNDEFINED_STATUS_LABEL = 'Undefined'

  def render_charts_grid # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    counts = @project.project_data.decisions.each_with_object(Hash.new(0)) do |item, cntr|
      cntr[item.record_type] += 1 if item.record_type
    end
    labels = counts.keys.sort
    data = labels.map { |k| counts[k] }
    pie_colors = labels.each_with_index.map { |_, i| palette_rgba(i, 0.5) }

    velocity = velocity_chart_data
    status_dist = status_distribution_chart_data

    <<~HTML
      <div class="decisions_overview_charts">
      \t<div class="chart_cell">
      \t\t<canvas id="decisions_type_pie"></canvas>
      \t\t<script>
      \t\t\tnew Chart(document.getElementById('decisions_type_pie'), {
      \t\t\t\ttype: 'pie',
      \t\t\t\tdata: {
      \t\t\t\t\tlabels: #{labels.to_json},
      \t\t\t\t\tdatasets: [{
      \t\t\t\t\t\tlabel: 'Decision records',
      \t\t\t\t\t\tdata: #{data.to_json},
      \t\t\t\t\t\tbackgroundColor: #{pie_colors.to_json},
      \t\t\t\t\t\tborderWidth: 0
      \t\t\t\t\t}]
      \t\t\t\t},
      \t\t\t\toptions: { plugins: { title: { display: true, text: 'Decision Records by Type' } } }
      \t\t\t});
      \t\t</script>
      \t</div>
      \t<div class="chart_cell">
      \t\t<canvas id="decisions_velocity_bar"></canvas>
      \t\t<script>
      \t\t\tnew Chart(document.getElementById('decisions_velocity_bar'), {
      \t\t\t\ttype: 'bar',
      \t\t\t\tdata: #{velocity.to_json},
      \t\t\t\toptions: {
      \t\t\t\t\tplugins: { title: { display: true, text: 'Decision Records by Status Over Time' } },
      \t\t\t\t\tscales: { x: { stacked: true }, y: { stacked: true, ticks: { precision: 0 } } }
      \t\t\t\t}
      \t\t\t});
      \t\t</script>
      \t</div>
      \t<div class="chart_cell">
      \t\t<canvas id="decisions_status_bar"></canvas>
      \t\t<script>
      \t\t\tnew Chart(document.getElementById('decisions_status_bar'), {
      \t\t\t\ttype: 'bar',
      \t\t\t\tdata: #{status_dist.to_json},
      \t\t\t\toptions: {
      \t\t\t\t\tindexAxis: 'y',
      \t\t\t\t\tplugins: { title: { display: true, text: 'Decision Records by Current Status' }, legend: { display: false } },
      \t\t\t\t\tscales: { x: { beginAtZero: true, ticks: { precision: 0 } } }
      \t\t\t\t}
      \t\t\t});
      \t\t</script>
      \t</div>
      </div>
    HTML
  end

  def velocity_chart_data(reference_date: Date.today, weeks: 6) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    fridays = recent_fridays(reference_date, weeks)
    segments = []
    counts = {}

    fridays.each_with_index do |friday, i|
      @project.project_data.decisions.each do |doc|
        status = doc.effective_status_on(friday)
        next if status.nil?

        unless counts.key?(status)
          counts[status] = Array.new(fridays.length, 0)
          segments << status
        end
        counts[status][i] += 1
      end
    end

    {
      labels: fridays.map { |f| f.strftime('%d-%m-%Y') },
      datasets: segments.map { |s| { label: s, data: counts[s] } }
    }
  end

  # Tally each decision record under its current status (the "*"-marked Status
  # row). Records whose current status is undefined fall under "Undefined", which
  # is ordered last; real statuses keep first-seen order. The count is baked into
  # each label so small categories stay legible on a linear axis next to a
  # dominant one.
  def status_distribution_chart_data # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    counts = Hash.new(0)
    keys = []
    @project.project_data.decisions.each do |doc|
      status = doc.current_status
      key = status.nil? || status.strip.empty? ? UNDEFINED_STATUS_LABEL : status
      keys << key unless counts.key?(key)
      counts[key] += 1
    end
    keys << UNDEFINED_STATUS_LABEL if keys.delete(UNDEFINED_STATUS_LABEL)

    colors = keys.each_with_index.map do |k, i|
      k == UNDEFINED_STATUS_LABEL ? palette_rgba(CHART_PALETTE.length - 1, 0.5) : palette_rgba(i, 0.5)
    end
    {
      labels: keys.map { |k| "#{k} (#{counts[k]})" },
      datasets: [{ label: 'Decision records', data: keys.map { |k| counts[k] },
                   backgroundColor: colors, borderWidth: 0 }]
    }
  end

  def palette_rgba(index, alpha)
    r, g, b = CHART_PALETTE[index % CHART_PALETTE.length]
    "rgba(#{r}, #{g}, #{b}, #{alpha})"
  end

  def recent_fridays(reference_date, count)
    friday_wday = 5
    days_back = (reference_date.wday - friday_wday) % 7
    most_recent = reference_date - days_back
    (0...count).to_a.reverse.map { |i| most_recent - (7 * i) }
  end
end
