# frozen_string_literal: true

require 'date'
require 'json'
require_relative 'base_document'
require_relative 'decision_grouping'
require_relative 'planning_dates'
require_relative '../html_safe'
require_relative '../project/critical_chain'
require_relative '../project/fever_chart'
require_relative '../project/working_calendar'

# The dedicated Critical Chain & Project Buffer page (ENH-202): one block per
# decision group, each showing the ordered critical chain rows, the project
# buffer, and the projected duration; a group with no estimates is marked
# unestimated. The chain and buffer are ADR-195's CriticalChain, reused
# unchanged -- this page only relocates the rendering off the overview.
class CriticalChainPage < BaseDocument
  include HtmlSafe
  include DecisionGrouping
  include PlanningDates

  # Recent Fridays sampled for the fever-chart trail (ADR-196), matching the
  # velocity chart's window.
  FEVER_TRAIL_WEEKS = 6

  attr_accessor :project

  def initialize(project)
    super()
    @project = project
    @title = 'Critical Chain & Project Buffer'
    @id = 'critical-chain'
  end

  def to_console
    puts "\e[36mCritical Chain: #{@id}\e[0m"
  end

  def needs_chartjs?
    true
  end

  def to_html(output_file_path)
    html_rows = ['', "<h1>#{@title}</h1>\n", render_critical_chain]
    save_html_to_file(html_rows, nil, output_file_path)
  end

  private

  def render_critical_chain
    ratio = @project.configuration.get_buffer_ratio
    hours_per_day = @project.configuration.get_hours_per_day
    lookup = record_lookup
    blocks = grouped_work_items.each_with_index.map do |(name, items), index|
      critical_chain_block(name, items, ratio, lookup, hours_per_day, index)
    end
    blocks << %(\t<p class="cc_unestimated">No decision records to plan.</p>\n) if blocks.empty?
    %(<div class="critical_chain">\n#{blocks.join}</div>\n)
  end

  # An upcased-record-id => Decision map, so a chain row can reach its owning
  # record's effort log (ADR-196).
  def record_lookup
    @project.project_data.decisions.to_h { |doc| [doc.id.to_s.upcase, doc] }
  end

  # The shared working calendar (ADR-205) projecting the working-day projected
  # duration onto a real completion date.
  def working_calendar
    @working_calendar ||= WorkingCalendar.new(anchor: @project.configuration.get_start_date,
                                              holidays: @project.configuration.get_holidays)
  end

  def critical_chain_block(name, items, ratio, lookup, hours_per_day, index) # rubocop:disable Metrics/ParameterLists
    plan = CriticalChain.new(items, buffer_ratio: ratio)
    header = %(\t<div class="cc_group">\n\t\t<h3>#{escape_text(name)}</h3>\n)
    body = if plan.estimated?
             cc_group_body(plan, lookup, hours_per_day, index)
           else
             %(\t\t<p class="cc_unestimated">No estimates — plan not sized.</p>\n)
           end
    "#{header}#{body}\t</div>\n"
  end

  # The estimated group's plan (chain table + buffer + projected duration) on the
  # left and its buffer-consumption fever chart on the right, side by side
  # (ADR-196). The chart is omitted when no chain row carries a positive estimate.
  def cc_group_body(plan, lookup, hours_per_day, index)
    fever = FeverChart.new(plan, lookup, hours_per_day: hours_per_day)
    left = %(\t\t<div class="cc_plan">\n#{cc_chain_html(plan)}\t\t</div>\n)
    right = fever.plottable? ? %(\t\t<div class="cc_fever">\n#{fever_chart_html(fever, index)}\t\t</div>\n) : ''
    %(\t\t<div class="cc_group_body">\n#{left}#{right}\t\t</div>\n)
  end

  def cc_chain_html(plan)
    lines = [%(\t\t<table class="cc_chain">\n),
             "\t\t\t<thead><th>Record</th><th>Item</th><th>Owner</th><th>Duration</th></thead>\n"]
    plan.chain.each { |wi| lines << cc_chain_row(wi) }
    lines << "\t\t</table>\n"
    projected = format_days(plan.projected_duration)
    finish = working_calendar.date_for(plan.projected_duration)
    lines << %(\t\t<p class="cc_buffer">Project buffer: #{plan.buffer} working days</p>\n)
    lines << %(\t\t<p class="cc_projected">Projected duration: #{projected} working days</p>\n)
    lines << %(\t\t<p class="cc_finish">Projected completion: #{finish.strftime('%d-%m-%Y')}</p>\n)
    lines.join
  end

  def cc_chain_row(work_item)
    cells = [work_item.record_id.upcase, work_item.activity, work_item.owner, format_days(work_item.focused_estimate)]
    "\t\t\t<tr>#{cells.map { |c| "<td>#{escape_text(c.to_s)}</td>" }.join}</tr>\n"
  end

  # A working-day count without a trailing ".0" when it is whole.
  def format_days(value)
    value == value.to_i ? value.to_i.to_s : value.to_s
  end

  # The fever chart: the effort-only historical trail over recent Fridays plus the
  # live point (which credits Done rows), drawn over the green/yellow/red zones.
  def fever_chart_html(fever, index)
    today = Date.today
    points = fever.trail(recent_fridays(today, FEVER_TRAIL_WEEKS)) + [fever.live_point(today)]
    coords = points.map { |completion, consumption| { x: completion.round(2), y: consumption.round(2) } }
    radii = Array.new(coords.length - 1, 3) + [6]
    colors = points.map { |completion, consumption| zone_color(completion, consumption) }
    fever_canvas_script("fever_chart_#{index}", coords, radii, colors)
  end

  def fever_canvas_script(canvas_id, coords, radii, colors)
    <<~HTML
      \t\t\t<canvas id="#{canvas_id}" class="fever_canvas"></canvas>
      \t\t\t<script>
      \t\t\t#{fever_zone_plugin_js}
      \t\t\tnew Chart(document.getElementById('#{canvas_id}'), {
      \t\t\t\ttype: 'scatter',
      \t\t\t\tdata: { datasets: [{ label: 'Buffer health', data: #{coords.to_json}, showLine: true,
      \t\t\t\t\tborderColor: 'rgba(80,80,80,0.7)', pointRadius: #{radii.to_json},
      \t\t\t\t\tpointBackgroundColor: #{colors.to_json}, pointBorderColor: '#333' }] },
      \t\t\t\toptions: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } },
      \t\t\t\t\tscales: { x: { title: { display: true, text: 'Chain completion %' }, min: 0, max: 100 },
      \t\t\t\t\t\ty: { title: { display: true, text: 'Buffer consumption %' }, min: 0, suggestedMax: 100 } } },
      \t\t\t\tplugins: [window.feverZonesPlugin]
      \t\t\t});
      \t\t\t</script>
    HTML
  end

  # The conventional CCPM zone for a point: green below the lower one-third
  # diagonal, red above the upper, yellow between (ADR-196).
  def zone_color(completion, consumption)
    lower = (2.0 / 3.0) * completion
    upper = (100.0 / 3.0) + (2.0 / 3.0) * completion
    return '#2e9e2e' if consumption <= lower
    return '#e0a200' if consumption <= upper

    '#d33'
  end

  # A page-global Chart.js plugin (declared once, idempotently) that paints the
  # three fever zones behind every fever chart on the page.
  def fever_zone_plugin_js
    <<~JS.strip
      window.feverZonesPlugin = window.feverZonesPlugin || { id: 'feverZones', beforeDraw(chart) {
        const a = chart.chartArea; if (!a) return; const x = chart.scales.x, y = chart.scales.y;
        const px = v => x.getPixelForValue(v), py = v => y.getPixelForValue(v);
        const lower = c => (2/3)*c, upper = c => 100/3 + (2/3)*c, ctx = chart.ctx;
        ctx.save();
        ctx.fillStyle = 'rgba(224,162,0,0.10)'; ctx.fillRect(a.left, a.top, a.width, a.height);
        ctx.fillStyle = 'rgba(46,158,46,0.12)'; ctx.beginPath();
        ctx.moveTo(px(0), py(0)); ctx.lineTo(px(100), py(lower(100)));
        ctx.lineTo(px(100), py(y.min)); ctx.lineTo(px(0), py(y.min)); ctx.closePath(); ctx.fill();
        ctx.fillStyle = 'rgba(221,51,51,0.12)'; ctx.beginPath();
        ctx.moveTo(px(0), py(upper(0))); ctx.lineTo(px(100), py(100));
        ctx.lineTo(px(100), py(y.max)); ctx.lineTo(px(0), py(y.max)); ctx.closePath(); ctx.fill();
        ctx.restore();
      } };
    JS
  end
end
