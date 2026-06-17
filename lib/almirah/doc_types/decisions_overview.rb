# frozen_string_literal: true

require 'date'
require 'json'
require_relative 'base_document'
require_relative '../html_safe'
require_relative '../project/work_item_scheduler'

class DecisionsOverview < BaseDocument # rubocop:disable Style/Documentation,Metrics/ClassLength
  include HtmlSafe

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

  def to_html(output_file_path) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    html_rows = []
    html_rows.append('')
    html_rows.append "<h1>#{@title}</h1>\n"

    html_rows.append render_charts_grid
    html_rows.append render_workitem_gantt

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
    html_rows.append "\t\t<th title=\"Cross-record full-kit readiness\">Kit</th>\n"
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
      target_date_html = doc.target_date ? doc.target_date.strftime('%d-%m-%Y') : ''
      s += "\t\t<td class=\"item_meta\">#{target_date_html}</td>\n"
      s += "\t\t<td class=\"item_meta\">#{doc.target_release_version}</td>\n"
      s += "\t\t<td class=\"item_meta\">#{doc.owners.join(', ')}</td>\n"
      s += kit_overview_cell(doc)
      s += "</tr>\n"
      html_rows.append s
    end
    html_rows.append "</table>\n"

    save_html_to_file(html_rows, nil, output_file_path)
  end

  private

  # Cross-record full-kit readiness for a record (ADR-194), rendered as text:
  # empty when the record declares no Depends On prerequisites, "Ready" when
  # every Scope row is kitted, "Blocked" (warning colour) otherwise. A record
  # blocked while having a started row (a cross-record violation) is emphasised,
  # matching the console warning.
  def kit_overview_cell(doc)
    return "\t\t<td class=\"item_kit\"></td>\n" unless doc.declared_dependencies?
    return "\t\t<td class=\"item_kit kit_ready\">Ready</td>\n" if doc.fully_kitted?

    weight = doc.kit_started_violation? ? ' font-weight: bold;' : ''
    "\t\t<td class=\"item_kit kit_blocked\" style=\"color: #c0392b;#{weight}\">Blocked</td>\n"
  end

  # The resource-swimlane Gantt of the WorkItem network (ADR-198), placed between
  # the charts grid and the records table. One lane per owner (the same global
  # roster the WIP chart uses), an abstract day-index axis, and a constant-
  # duration bar per work item positioned by WorkItemScheduler (forward pass +
  # per-owner resource levelling). Omitted when there is nothing to schedule.
  def render_workitem_gantt
    items = @project.project_data.work_items.values
    owners = ordered_owners(in_progress_tally)
    scheduler = WorkItemScheduler.new(items)
    days = scheduler.day_count
    return '' if items.empty? || owners.empty? || days.zero?

    grid = gantt_grid(owners, items, scheduler, days)
    items.any?(&:cross_record_violation?) ? grid + gantt_pulse_script : grid
  end

  # Slow background pulse for blocked bars (cosmetic; no decision record). A
  # small inline script eases each blocked bar between its own status colour and
  # the Chart.js red over a 2.4s, six-phase cycle. The bar's border is untouched,
  # and the pulse is skipped under prefers-reduced-motion.
  def gantt_pulse_script
    <<~'JS'
      <script>
      (function () {
        if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) { return; }
        var target = [255, 99, 132];
        var steps = [0, 1 / 5, 1 / 3, 1, 1 / 3, 1 / 5];
        var bars = document.querySelectorAll('.workitem_gantt .gantt_blocked');
        if (!bars.length) { return; }
        var items = [];
        bars.forEach(function (el) {
          var m = getComputedStyle(el).backgroundColor.match(/\d+/g);
          if (!m) { return; }
          var base = [parseInt(m[0], 10), parseInt(m[1], 10), parseInt(m[2], 10)];
          var phases = steps.map(function (t) {
            return 'rgb(' + Math.round(base[0] + (target[0] - base[0]) * t) + ',' +
                            Math.round(base[1] + (target[1] - base[1]) * t) + ',' +
                            Math.round(base[2] + (target[2] - base[2]) * t) + ')';
          });
          el.style.transition = 'background-color 0.4s linear';
          items.push({ el: el, phases: phases });
        });
        var i = 0;
        setInterval(function () {
          i = (i + 1) % 6;
          items.forEach(function (it) { it.el.style.backgroundColor = it.phases[i]; });
        }, 400);
      })();
      </script>
    JS
  end

  def gantt_grid(owners, items, scheduler, days)
    starts = scheduler.start_days
    cols = "var(--gantt-owner-width) repeat(#{days}, var(--gantt-day-width))"
    rows = [%(<div class="workitem_gantt">\n), %(\t<div class="gantt_grid" style="grid-template-columns: #{cols};">\n)]
    rows.concat(gantt_header(days))
    owners.each_with_index { |owner, i| rows.concat(gantt_lane(owner, i + 2, items, starts, scheduler)) }
    rows << "\t</div>\n" << "</div>\n"
    rows.join
  end

  # Header row: the sticky corner over the Owner column, then one numbered cell
  # per day column.
  def gantt_header(days)
    cells = [%(\t\t<div class="gantt_corner" style="grid-row: 1; grid-column: 1;">Owner</div>\n)]
    (1..days).each do |d|
      cells << %(\t\t<div class="gantt_day_head" style="grid-row: 1; grid-column: #{d + 1};">#{d}</div>\n)
    end
    cells
  end

  # One owner lane: the sticky owner label plus that owner's scheduled bars.
  def gantt_lane(owner, row, items, starts, scheduler)
    cells = [%(\t\t<div class="gantt_owner" style="grid-row: #{row}; grid-column: 1;">#{escape_text(owner)}</div>\n)]
    items.select { |wi| wi.owner == owner }.each do |wi|
      cells << gantt_bar(wi, row, starts[wi], scheduler.duration_for(wi))
    end
    cells
  end

  # A single work-item bar spanning its duration from its start day, coloured by
  # row Status and emphasised when it is a started-but-blocked cross-record
  # violation (matching the Kit cell).
  def gantt_bar(work_item, row, start, span)
    classes = ['gantt_bar', gantt_status_class(work_item)]
    classes << 'gantt_blocked' if work_item.cross_record_violation?
    preds = work_item.predecessor_items.map(&:id)
    tip = preds.empty? ? 'No predecessors' : "After: #{preds.join(', ')}"
    label = "#{work_item.record_id.upcase} #{work_item.activity}"
    %(\t\t<div class="#{classes.join(' ')}" style="grid-row: #{row}; ) +
      %(grid-column: #{start + 1} / span #{span};" title="#{escape_attr(tip)}">#{escape_text(label)}</div>\n)
  end

  def gantt_status_class(work_item)
    case work_item.status
    when 'Done' then 'gantt_done'
    when 'In-Progress' then 'gantt_inprogress'
    else 'gantt_todo'
    end
  end

  CHART_PALETTE = [
    [54, 162, 235], [255, 99, 132], [255, 159, 64], [255, 205, 86],
    [75, 192, 192], [153, 102, 255], [201, 203, 207]
  ].freeze

  # Records with a missing or ambiguous current-status marker are surfaced under
  # this category as a data-quality indicator rather than being silently dropped.
  UNDEFINED_STATUS_LABEL = 'Undefined'

  def render_charts_grid
    wip = wip_by_owner_chart_data
    velocity = velocity_chart_data
    status_dist = status_distribution_chart_data

    <<~HTML
      <div class="decisions_overview_charts">
      \t<div class="chart_cell">
      \t\t<canvas id="decisions_wip_bar"></canvas>
      \t\t<script>
      \t\t\tnew Chart(document.getElementById('decisions_wip_bar'), {
      \t\t\t\ttype: 'bar',
      \t\t\t\tdata: {
      \t\t\t\t\tlabels: #{wip[:labels].to_json},
      \t\t\t\t\tdatasets: [
      \t\t\t\t\t\t{ label: 'In-progress items', data: #{wip[:bars].to_json}, backgroundColor: #{wip[:bar_colors].to_json}, borderWidth: 0, order: 2 },
      \t\t\t\t\t\t{ type: 'line', label: 'WIP limit', data: #{wip[:limit_line].to_json}, borderColor: 'rgba(255, 99, 132, 1)', borderDash: [6, 4], pointRadius: 0, fill: false, order: 1 }
      \t\t\t\t\t]
      \t\t\t\t},
      \t\t\t\toptions: {
      \t\t\t\t\tplugins: { title: { display: true, text: 'Work In Progress by Owner' } },
      \t\t\t\t\tscales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
      \t\t\t\t}
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

  # Show a bar for EVERY owner named in any decision record's Scope table, its
  # height being that owner's count of In-Progress Scope rows across all records
  # (zero when the owner has none). Rendering the full roster of roles keeps the
  # freeze line spanning the chart even when only one owner is currently busy --
  # a single bar would otherwise leave the category-aligned limit line with one
  # point and nothing to draw. Bars are ordered by descending count, idle owners
  # (tied at zero) last in first-seen order; an owner over the limit uses the
  # warning colour. The limit is a flat line dataset so the threshold needs no plugin.
  def wip_by_owner_chart_data
    tally = in_progress_tally
    owners = ordered_owners(tally)
    limit = @project.configuration.get_wip_limit
    {
      labels: owners,
      bars: owners.map { |owner| tally[owner] },
      bar_colors: owners.map { |owner| tally[owner] > limit ? palette_rgba(1, 0.7) : palette_rgba(0, 0.5) },
      limit_line: Array.new(owners.length, limit)
    }
  end

  # In-Progress Scope-row count per owner, across all decision records.
  def in_progress_tally
    tally = Hash.new(0)
    @project.project_data.decisions.each do |doc|
      doc.in_progress_owner_tally.each { |owner| tally[owner] += 1 }
    end
    tally
  end

  # Every owner named in any Scope table, ordered by descending in-progress count;
  # idle owners (tied at zero) fall to the end in first-seen order.
  def ordered_owners(tally)
    first_seen = []
    @project.project_data.decisions.each do |doc|
      doc.owners.each { |owner| first_seen << owner unless first_seen.include?(owner) }
    end
    first_seen.sort_by { |owner| [-tally[owner], first_seen.index(owner)] }
  end

  # Retained for re-enablement: the original "Decision Records by Type" pie chart.
  # Its cell is no longer emitted into the charts grid (the WIP-by-Owner chart took
  # the left slot), but the builder is kept intact so the pie can be restored by
  # emitting this cell again, with no data work.
  def pie_chart_cell # rubocop:disable Metrics/AbcSize
    counts = @project.project_data.decisions.each_with_object(Hash.new(0)) do |item, cntr|
      cntr[item.record_type] += 1 if item.record_type
    end
    labels = counts.keys.sort
    data = labels.map { |k| counts[k] }
    pie_colors = labels.each_with_index.map { |_, i| palette_rgba(i, 0.5) }

    <<~HTML
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
