# frozen_string_literal: true

require_relative 'work_item_scheduler'

# Resource-levelled scheduler variant for the critical chain (ADR-195): each
# row's duration is its focused estimate, and rows are prioritised by the longest
# downstream chain of focused durations (ties: record sequence, then step). The
# forward pass, resource levelling, binding-predecessor tracking, and chain
# tracing are all inherited from WorkItemScheduler.
class ChainScheduler < WorkItemScheduler
  def duration_for(work_item)
    work_item.focused_estimate
  end

  private

  def priority_key(work_item, memo)
    [-downstream_length(work_item, memo, []), work_item.record_sequence, work_item.step]
  end

  # The longest path of focused durations from this row through its in-scope
  # successors to a sink. Memoised and cycle-guarded.
  def downstream_length(work_item, memo, stack)
    return memo[work_item] if memo.key?(work_item)
    return duration_for(work_item) if stack.include?(work_item)

    stack.push(work_item)
    tail = scoped_successors(work_item).map { |s| downstream_length(s, memo, stack) }.max || 0
    stack.pop
    memo[work_item] = duration_for(work_item) + tail
  end
end

# The Gantt's scheduler (ADR-201/195): real focused-estimate durations like the
# critical-chain scheduler, but rounded up to whole day columns with a one-day
# minimum so an unestimated row (focused 0) still shows a visible bar. The chain
# and buffer keep their exact-duration math in ChainScheduler / CriticalChain.
class GanttScheduler < ChainScheduler
  def duration_for(work_item)
    [work_item.focused_estimate.ceil, 1].max
  end
end

# The critical chain and project buffer for one decision group's Scope rows
# (ADR-195). This object serves two distinct jobs that want opposite treatment of
# completed work, so it keeps two views of the same Scope rows:
#
# - the *scheduling* chain (`chain` / `buffer` / `projected_duration`) excludes
#   Done rows as finished work — you do not re-schedule what is already done — and
#   reports the duration of the work still remaining;
# - the *baseline* chain (`baseline_chain` / `baseline_buffer`) keeps every row,
#   Done included, as the plan was originally sized. Buffer-consumption accounting
#   (the fever chart, ADR-196) reads this view so that a chain row which overran
#   and then completed keeps consuming buffer instead of vanishing the moment it
#   is marked Done, and so the consumption denominator stays a stable plan-time
#   baseline rather than shrinking as rows finish (issue-207).
#
# A predecessor outside the given set (a row in another group) drops out and is
# treated as an already-available input. The buffer aggregates the safety
# (safe - focused, clamped at 0) along a chain and cuts it by buffer_ratio,
# rounded up.
class CriticalChain
  def initialize(work_items, buffer_ratio: 0.5)
    @all_items = work_items
    @items = work_items.reject(&:done?)
    @buffer_ratio = buffer_ratio
    @scheduler = ChainScheduler.new(@items)
    @baseline_scheduler = ChainScheduler.new(@all_items)
  end

  # The remaining chain (Done rows excluded) in start order — drives the chain
  # table and the projected completion of the work still to do.
  def chain
    @scheduler.critical_chain
  end

  # The chain as originally planned, completed rows included (issue-207). Buffer
  # consumption is accounted against this set so completed overruns stay visible.
  def baseline_chain
    @baseline_scheduler.critical_chain
  end

  # Chain length in working days (the latest finish).
  def length
    @scheduler.makespan
  end

  # ceil(buffer_ratio * Σ_chain max(safe - focused, 0)) over the remaining chain.
  def buffer
    buffer_for(chain)
  end

  # The plan-time buffer over the full baseline chain — the stable denominator for
  # buffer-consumption %, unaffected by rows completing (issue-207).
  def baseline_buffer
    buffer_for(baseline_chain)
  end

  def projected_duration
    length + buffer
  end

  # False when no row carries a positive focused estimate, so the overview marks
  # the group "unestimated" rather than reporting a misleadingly short plan.
  # Reads the baseline so a fully-completed group still reports as estimated and
  # keeps its (100%-complete) fever chart instead of collapsing to "not sized".
  def estimated?
    @all_items.any? { |wi| wi.focused_estimate.positive? }
  end

  private

  def buffer_for(rows)
    safety = rows.sum { |wi| [wi.safe_estimate - wi.focused_estimate, 0].max }
    (@buffer_ratio * safety).ceil
  end
end
