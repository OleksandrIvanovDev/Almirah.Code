# frozen_string_literal: true

# The buffer-consumption fever chart for one decision group (ADR-196): given the
# group's CriticalChain plan, the effort logged on its records, and the working-
# hours-per-day conversion, it produces the (completion%, consumption%) point and
# the historical trail the Critical Chain page plots.
#
# It tracks only chain rows with a positive focused estimate (a zero-estimate row
# carries no schedule weight). Per-row actual effort is read from the owning
# Decision's append-only # Effort log via row_actual_hours_on, converted to days;
# the chart never consults the record lifecycle status.
#
# It reads the plan's *baseline* chain and buffer (completed rows included,
# issue-207), not the remaining-work chain: a chain row that overran and then was
# marked Done has consumed real buffer that must stay accounted, and the
# consumption denominator must not shrink as rows finish. The live point still
# credits a Done row in full via its per-row Status (ADR-196); historical trail
# points reconstruct even a completed row's progress and overrun from its dated
# # Effort log, which a per-row Status (no dated history) could not.
class FeverChart
  # record_lookup maps an upcased record id (e.g. "ADR-196") to its Decision.
  def initialize(plan, record_lookup, hours_per_day: 8)
    @rows = plan.baseline_chain.select { |wi| wi.focused_estimate.positive? }
    @buffer = plan.baseline_buffer
    @record_lookup = record_lookup
    @hours_per_day = hours_per_day.to_f
  end

  # True when there is anything to plot (at least one positive-estimate chain row).
  def plottable?
    @rows.any?
  end

  # The live fever point [completion%, consumption%] as of `date`: a Done row
  # credits full completion regardless of logged effort, matching the bounded
  # per-row Status (ADR-193); other rows credit logged effort only.
  def live_point(date)
    [completion(date, live: true), consumption(date)]
  end

  # A historical point [completion%, consumption%] as of `date`, from logged
  # effort only (the per-row Status has no dated history to replay).
  def point_on(date)
    [completion(date, live: false), consumption(date)]
  end

  # One historical point per date (recent Fridays), in the given order.
  def trail(dates)
    dates.map { |d| point_on(d) }
  end

  private

  def completion(date, live:)
    total = @rows.sum(&:focused_estimate)
    return 0.0 if total.zero?

    credited = @rows.sum { |wi| credit(wi, date, live: live) * wi.focused_estimate }
    100.0 * credited / total
  end

  def credit(work_item, date, live:)
    return 1.0 if live && work_item.done?

    clamp01(actual_days(work_item, date) / work_item.focused_estimate)
  end

  # Percentage of the project buffer consumed: the aggregate amount by which chain
  # rows overran their focused estimate, over the buffer. May exceed 100. A group
  # whose chain carries no safety (buffer 0) has nothing to consume, so 0.
  def consumption(date)
    return 0.0 if @buffer.zero?

    consumed = @rows.sum { |wi| [actual_days(wi, date) - wi.focused_estimate, 0].max }
    100.0 * consumed / @buffer
  end

  def actual_days(work_item, date)
    record = @record_lookup[work_item.record_id.to_s.upcase]
    return 0.0 if record.nil? || @hours_per_day.zero?

    record.row_actual_hours_on(work_item.activity, date) / @hours_per_day
  end

  def clamp01(value)
    value.clamp(0.0, 1.0)
  end
end
