# frozen_string_literal: true

require 'set'

# Lays the WorkItem network (ADR-194) on an abstract day axis for the overview
# swimlane Gantt (ADR-198). It performs a deterministic forward pass over the
# dependency edges and then levels each owner's lane so two work items of the
# same owner never overlap. Levelling backfills: a row may be slotted into an
# idle gap left between rows placed earlier, so a low-priority short row does
# not queue behind the whole lane when a gap already fits it.
#
# Durations are a constant placeholder (3 days) while no per-row estimates
# exist; `duration_for` is the single hook ADR-195 overrides to feed real
# estimates without changing the scheduling logic.
#
# Days are 1-based. A work item starting on day `s` with duration `d` occupies
# the inclusive day span `s .. s + d - 1`; its *finish* (the next free day,
# returned in the ends map) is `s + d`, the earliest a successor or the same
# owner's next item may start.
class WorkItemScheduler
  # Placeholder duration for every work item until ADR-195 supplies estimates.
  DEFAULT_DURATION = 3

  def initialize(work_items, duration: DEFAULT_DURATION)
    @items = work_items
    @duration = duration
    @item_set = work_items.to_set
  end

  # { work_item => start_day }, day index 1-based. Empty when there are no items.
  def start_days
    schedule unless @starts
    @starts
  end

  # The number of day columns the chart needs: the latest finish minus one
  # (finishes are the exclusive next-free day). Zero when there are no items.
  def day_count
    schedule unless @ends
    @ends.empty? ? 0 : (@ends.values.max - 1)
  end

  # The schedule length in working days (the latest finish, day 1 being the start).
  def makespan
    day_count
  end

  # The critical chain: the row with the latest finish, traced back through its
  # binding predecessors (the dependency and resource hand-offs that set each
  # row's start), returned in start order. Empty when nothing is scheduled.
  def critical_chain
    schedule unless @starts
    return [] if @ends.empty?

    max_end = @ends.values.max
    node = @items.select { |wi| @ends[wi] == max_end }.min_by { |wi| [wi.record_id, wi.step] }
    chain = []
    while node
      chain.unshift(node)
      node = @binding[node]
    end
    chain
  end

  def duration_for(_work_item)
    @duration
  end

  private

  # Greedy list-scheduler. Items are processed in a deterministic priority order
  # (resource-free earliest start, then activity rank, record id, step) so that
  # every item's predecessors are placed before it. Each item starts at the
  # earliest day at or after its dependency finish where its owner's lane has an
  # idle gap wide enough for it (resource levelling with backfill).
  def schedule
    @starts = {}
    @ends = {}
    @binding = {}
    @owner_rows = Hash.new { |hash, owner| hash[owner] = [] }
    return if @items.empty?

    priority_order.each { |wi| place(wi) }
  end

  # Assigns one work item its start day, records the predecessor that bound that
  # start, then marks the span as occupied in its owner's lane.
  def place(work_item)
    preds = scoped_predecessors(work_item)
    dep_finish = preds.map { |p| @ends[p] || 1 }.max || 1
    start, lane_pred = earliest_fit(work_item.owner, dep_finish, duration_for(work_item))
    @starts[work_item] = start
    @ends[work_item] = start + duration_for(work_item)
    @binding[work_item] = binding_predecessor(preds, start, lane_pred)
    @owner_rows[work_item.owner] << work_item unless work_item.owner.empty?
  end

  # The earliest start at or after `from` where the owner's lane stays clear for
  # `duration` days, plus the lane row whose finish that start had to wait behind
  # (nil when the row starts at `from` itself). A blank owner holds no resource,
  # so it never serialises.
  def earliest_fit(owner, from, duration)
    return [from, nil] if owner.empty?

    start = from
    lane_pred = nil
    @owner_rows[owner].sort_by { |row| @starts[row] }.each do |row|
      break if start + duration <= @starts[row]
      next if @ends[row] <= start

      start = @ends[row]
      lane_pred = row
    end
    [start, lane_pred]
  end

  # The already-placed predecessor whose finish coincides with this row's start --
  # the dependency or same-owner hand-off the critical chain is traced back
  # through. nil when the row starts at the origin with no such predecessor.
  def binding_predecessor(preds, start, lane_pred)
    candidates = preds.select { |p| @ends[p] == start }
    candidates << lane_pred if lane_pred
    candidates.min_by { |c| [c.record_id, c.step] }
  end

  def priority_order
    memo = {}
    @items.sort_by { |wi| priority_key(wi, memo) }
  end

  # The deterministic scheduling priority for a row. Overridden by the critical-
  # chain scheduler (ADR-195) to prioritise the longest downstream duration.
  def priority_key(work_item, memo)
    [dependency_start(work_item, memo, []), work_item.activity_rank, work_item.record_id, work_item.step]
  end

  # The earliest day this item could start ignoring resource contention: 1 when
  # it has no predecessors, else one past the latest predecessor finish. Memoised
  # and cycle-guarded — a back-edge (which the DAG-by-construction network should
  # never have) is treated as start 1 so scheduling still completes.
  def dependency_start(work_item, memo, stack)
    return memo[work_item] if memo.key?(work_item)
    return 1 if stack.include?(work_item)

    preds = scoped_predecessors(work_item)
    return memo[work_item] = 1 if preds.empty?

    stack.push(work_item)
    earliest = preds.map { |p| dependency_start(p, memo, stack) + duration_for(p) }.max
    stack.pop
    memo[work_item] = earliest
  end

  # Predecessors inside this scheduler's own item set. A predecessor scheduled in
  # another scope (e.g. a different decision group, ADR-201) is treated as an
  # already-available external input: it is dropped here and imposes no finish
  # constraint, so the dependent simply starts at day 1 with respect to it.
  def scoped_predecessors(work_item)
    work_item.predecessor_items.select { |p| @item_set.include?(p) }
  end

  # Successors inside this scheduler's own item set (the mirror of
  # scoped_predecessors), used by the critical-chain priority.
  def scoped_successors(work_item)
    work_item.successor_items.select { |s| @item_set.include?(s) }
  end
end
