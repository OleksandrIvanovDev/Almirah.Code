# frozen_string_literal: true

require_relative 'base_document'
require_relative 'decision_grouping'
require_relative '../html_safe'
require_relative '../project/critical_chain'

# The dedicated Critical Chain & Project Buffer page (ENH-202): one block per
# decision group, each showing the ordered critical chain rows, the project
# buffer, and the projected duration; a group with no estimates is marked
# unestimated. The chain and buffer are ADR-195's CriticalChain, reused
# unchanged -- this page only relocates the rendering off the overview.
class CriticalChainPage < BaseDocument
  include HtmlSafe
  include DecisionGrouping

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

  def to_html(output_file_path)
    html_rows = ['', "<h1>#{@title}</h1>\n", render_critical_chain]
    save_html_to_file(html_rows, nil, output_file_path)
  end

  private

  def render_critical_chain
    ratio = @project.configuration.get_buffer_ratio
    blocks = grouped_work_items.map { |name, items| critical_chain_block(name, items, ratio) }
    blocks << %(\t<p class="cc_unestimated">No decision records to plan.</p>\n) if blocks.empty?
    %(<div class="critical_chain">\n#{blocks.join}</div>\n)
  end

  def critical_chain_block(name, items, ratio)
    plan = CriticalChain.new(items, buffer_ratio: ratio)
    header = %(\t<div class="cc_group">\n\t\t<h3>#{escape_text(name)}</h3>\n)
    body = plan.estimated? ? cc_chain_html(plan) : %(\t\t<p class="cc_unestimated">No estimates — plan not sized.</p>\n)
    "#{header}#{body}\t</div>\n"
  end

  def cc_chain_html(plan)
    lines = [%(\t\t<table class="cc_chain">\n),
             "\t\t\t<thead><th>Record</th><th>Item</th><th>Owner</th><th>Duration</th></thead>\n"]
    plan.chain.each { |wi| lines << cc_chain_row(wi) }
    lines << "\t\t</table>\n"
    projected = format_days(plan.projected_duration)
    lines << %(\t\t<p class="cc_buffer">Project buffer: #{plan.buffer} working days</p>\n)
    lines << %(\t\t<p class="cc_projected">Projected duration: #{projected} working days</p>\n)
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
end
