# frozen_string_literal: true

require 'date'
require 'json'
require_relative 'base_document'
require_relative 'decision_grouping'
require_relative 'planning_dates'
require_relative '../html_safe'
require_relative '../project/work_item_scheduler'
require_relative '../project/critical_chain'
require_relative '../project/working_calendar'

class DecisionsOverview < BaseDocument # rubocop:disable Style/Documentation,Metrics/ClassLength
  include HtmlSafe
  include DecisionGrouping
  include PlanningDates

  attr_accessor :project

  def initialize(project)
    super()
    @project = project
    @title = 'Decision Records Overview'
    @id = 'overview'
  end

  def needs_chartjs?
    true
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

  # Day columns inserted between adjacent group blocks (ADR-201).
  GANTT_GUTTER_DAYS = 1

  # The group-segmented resource-swimlane Gantt of the WorkItem network (ADR-198,
  # segmented by ADR-201), placed between the charts grid and the records table.
  # Each decision group (ADR-197) becomes a block laid left to right; within a
  # block, one lane per owner (the shared WIP roster) carries a constant-duration
  # bar per work item positioned by WorkItemScheduler. A group band row labels
  # each block and a Buffer lane closes the grid below the owner lanes. Omitted
  # when there is nothing to schedule.
  def render_workitem_gantt
    blocks = gantt_blocks
    owners = consensus_owner_order
    return '' if blocks.empty? || owners.empty?

    total_days = blocks.last[:offset] + blocks.last[:cal_width]
    grid = gantt_grid(owners, blocks, total_days)
    gantt_any_blocked?(blocks) ? grid + gantt_pulse_script : grid
  end

  # True when any scheduled work item is a started-but-blocked cross-record
  # violation, so the pulse script is worth emitting.
  def gantt_any_blocked?(blocks)
    blocks.any? { |b| b[:items].any?(&:cross_record_violation?) }
  end

  # One block per decision group (ADR-197) that has work items, in decision_groups
  # (folder-encounter) order. Each block runs WorkItemScheduler over only its own
  # items, so a cross-group predecessor falls away as an already-available input
  # (ADR-201); blocks are offset left to right with a one-column gutter between.
  def gantt_blocks # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    ratio = @project.configuration.get_buffer_ratio
    calendar = WorkingCalendar.new(anchor: @project.configuration.get_start_date,
                                   holidays: @project.configuration.get_holidays)
    offset = 0
    grouped_work_items.each_with_object([]) do |(name, items), blocks|
      scheduler = GanttScheduler.new(items)
      next if scheduler.day_count.zero?

      offset += GANTT_GUTTER_DAYS unless blocks.empty?
      block = gantt_block(name, items, scheduler, offset, ratio, calendar)
      blocks << block
      offset += block[:cal_width]
    end
  end

  # One block descriptor: its group name, work items, schedule, per-work-item
  # start days, the working span and computed project buffer (ADR-195), the
  # shared working calendar (ADR-205), the block's calendar-column width, and the
  # left-to-right column offset of the block's first day.
  def gantt_block(name, items, scheduler, offset, ratio, calendar) # rubocop:disable Metrics/ParameterLists
    work_days = scheduler.day_count
    buffer = CriticalChain.new(items, buffer_ratio: ratio).buffer
    width = work_days + buffer
    { name:, items:, scheduler:, starts: scheduler.start_days,
      work_days:, buffer:, width:, calendar:,
      cal_width: calendar.columns(width).length, offset: }
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

  def gantt_grid(owners, blocks, total_days) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    cols = "var(--gantt-owner-width) repeat(#{total_days}, var(--gantt-day-width))"
    rows = [%(<div class="workitem_gantt">\n), %(\t<div class="gantt_grid" style="grid-template-columns: #{cols};">\n)]
    total_rows = owners.length + 4
    rows.concat(gantt_nonworking_columns(blocks, total_rows))
    rows.concat(gantt_month_header(blocks))
    rows.concat(gantt_day_header(blocks))
    rows.concat(gantt_group_band(blocks))
    owners.each_with_index { |owner, i| rows.concat(gantt_lane(owner, i + 4, blocks)) }
    rows.concat(gantt_buffer_lane(blocks, owners.length + 4))
    rows << "\t</div>\n" << "</div>\n"
    rows.join
  end

  # Full-height shaded background column behind every non-working calendar day
  # (weekends and holidays, ADR-205), spanning the lane rows so the shading shows
  # under the bars. Emitted first so the bars paint on top.
  def gantt_nonworking_columns(blocks, total_rows)
    cells = []
    blocks.each do |b|
      b[:calendar].columns(b[:width]).each_with_index do |date, i|
        next unless b[:calendar].non_working?(date)

        style = %(grid-row: 3 / span #{total_rows - 2}; grid-column: #{b[:offset] + i + 2};)
        cells << %(\t\t<div class="gantt_nonworking_col" style="#{style}"></div>\n)
      end
    end
    cells
  end

  # Month band (row 1): the sticky corner over the Owner column spanning both
  # header rows, then one cell per calendar month spanning that month's columns
  # within each block (ADR-205).
  def gantt_month_header(blocks)
    cells = [%(\t\t<div class="gantt_corner" style="grid-row: 1 / span 2; grid-column: 1;">Owner</div>\n)]
    blocks.each do |b|
      month_spans(b[:calendar].columns(b[:width])).each do |label, start_i, len|
        style = %(grid-row: 1; grid-column: #{b[:offset] + start_i + 2} / span #{len};)
        cells << %(\t\t<div class="gantt_month_head" style="#{style}">#{label}</div>\n)
      end
    end
    cells
  end

  # Day-of-month row (row 2): one numbered cell per calendar column within each
  # block, flagged non-working for weekends and holidays (ADR-205).
  def gantt_day_header(blocks)
    cells = []
    blocks.each do |b|
      b[:calendar].columns(b[:width]).each_with_index do |date, i|
        col = b[:offset] + i + 2
        klass = b[:calendar].non_working?(date) ? 'gantt_day_head gantt_nonworking' : 'gantt_day_head'
        cells << %(\t\t<div class="#{klass}" style="grid-row: 2; grid-column: #{col};">#{date.day}</div>\n)
      end
    end
    cells
  end

  # Group consecutive calendar dates by month into [label, start_index, length].
  def month_spans(dates)
    dates.each_with_index.each_with_object([]) do |(date, i), spans|
      label = date.strftime('%b %Y')
      if spans.last && spans.last[0] == label
        spans.last[2] += 1
      else
        spans << [label, i, 1]
      end
    end
  end

  # The group band row (ADR-201), now row 3 below the two calendar header rows:
  # one labelled cell per block spanning that block's calendar columns, with a
  # sticky-left corner over the Owner column.
  def gantt_group_band(blocks)
    cells = [%(\t\t<div class="gantt_band_corner" style="grid-row: 3; grid-column: 1;"></div>\n)]
    blocks.each do |b|
      style = %(grid-row: 3; grid-column: #{b[:offset] + 2} / span #{b[:cal_width]};)
      cells << %(\t\t<div class="gantt_release_band" style="#{style}">#{escape_text(b[:name])}</div>\n)
    end
    cells
  end

  # The Buffer lane (ADR-201), the last row below the owner lanes: one buffer bar
  # per block, placed on the calendar columns of the working days immediately
  # after that group's last work item and spanning its buffer (ADR-195/205).
  def gantt_buffer_lane(blocks, row)
    cells = [%(\t\t<div class="gantt_buffer" style="grid-row: #{row}; grid-column: 1;">Buffer</div>\n)]
    blocks.each do |b|
      next if b[:buffer].zero?

      grid_col, span = calendar_span(b, b[:work_days] + 1, b[:buffer])
      tip = "Project buffer (#{b[:buffer]} working days)"
      style = %(grid-row: #{row}; grid-column: #{grid_col} / span #{span};)
      cells << %(\t\t<div class="gantt_buffer_bar" style="#{style}" title="#{escape_attr(tip)}">buffer</div>\n)
    end
    cells
  end

  # One owner lane across all blocks: the sticky owner label plus that owner's
  # scheduled bars in each block, offset into the block's day columns.
  def gantt_lane(owner, row, blocks)
    cells = [%(\t\t<div class="gantt_owner" style="grid-row: #{row}; grid-column: 1;">#{escape_text(owner)}</div>\n)]
    blocks.each do |b|
      b[:items].select { |wi| wi.owner == owner }.each do |wi|
        cells << gantt_bar(wi, row, b)
      end
    end
    cells
  end

  # A single work-item bar spanning, on the calendar axis (ADR-205), from its
  # first to its last working day inclusive -- so it covers any intervening
  # non-working columns without counting them. Coloured by row Status and
  # emphasised when it is a started-but-blocked cross-record violation.
  def gantt_bar(work_item, row, block)
    grid_col, span = calendar_span(block, block[:starts][work_item], block[:scheduler].duration_for(work_item))
    classes = ['gantt_bar', gantt_status_class(work_item)]
    classes << 'gantt_blocked' if work_item.cross_record_violation?
    label = "#{work_item.record_id.upcase} #{work_item.activity}"
    style = %(grid-row: #{row}; grid-column: #{grid_col} / span #{span};)
    %(\t\t<div class="#{classes.join(' ')}" style="#{style}" title="#{escape_attr(bar_tooltip(work_item))}">) +
      %(#{escape_text(label)}</div>\n)
  end

  # The predecessor hint shown on a bar's tooltip.
  def bar_tooltip(work_item)
    preds = work_item.predecessor_items.map(&:id)
    preds.empty? ? 'No predecessors' : "After: #{preds.join(', ')}"
  end

  # The [grid-column start, calendar span] of a run of `duration` working days
  # beginning at working day start_wd, projected onto the block's calendar columns
  # so the run covers any non-working columns it crosses (ADR-205).
  def calendar_span(block, start_wd, duration)
    col_start = block[:calendar].column_index(start_wd)
    span = block[:calendar].column_index(start_wd + duration - 1) - col_start + 1
    [block[:offset] + col_start + 2, span]
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

  # The owner order for the Gantt lanes (ADR-204): the workflow sequence the
  # records collectively describe, rather than the heatmap's current-load order.
  # Each record's distinct owner sequence (doc.owners) votes on every ordered
  # owner pair into a pairwise-precedence tally (before[[a, b]] = records placing
  # a before b); owners are then ranked by Copeland score, with the first-seen
  # order as a deterministic tiebreak so the lanes are identical across runs.
  # Opposite-order records are simply outvoted, a missing role abstains, and an
  # added role is placed by the pairs it does appear in -- no special-casing.
  def consensus_owner_order
    first_seen, before = owner_precedence
    first_seen.sort_by { |owner| [-copeland_score(owner, first_seen, before), first_seen.index(owner)] }
  end

  # One pass over the records yielding both the first-seen owner roster and the
  # pairwise-precedence tally before[[a, b]] -- the number of records placing a
  # before b across every ordered pair of a record's distinct owners. Shared so
  # the consensus order needs no second iteration over the records (ADR-204).
  def owner_precedence
    first_seen = []
    before = Hash.new(0)
    @project.project_data.decisions.each do |doc|
      owners = doc.owners
      owners.each_with_index do |owner, i|
        first_seen << owner unless first_seen.include?(owner)
        owners.drop(i + 1).each { |later| before[[owner, later]] += 1 }
      end
    end
    [first_seen, before]
  end

  # Copeland score for one owner against the roster: +1 for every other owner it
  # precedes more often than it follows, -1 for the reverse, 0 when tied. One
  # integer per owner keeps the sort well-defined even if the pairwise majorities
  # form a cycle, so no cycle detection is needed (ADR-204).
  def copeland_score(owner, roster, before)
    roster.sum do |other|
      next 0 if other == owner

      before[[owner, other]] <=> before[[other, owner]]
    end
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
end
