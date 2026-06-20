# frozen_string_literal: true

require 'date'

# Shared date bucketing for the planning views (ADR-182): the recent Fridays a
# time-series trail is sampled on. Used by the overview's velocity chart and the
# Critical Chain page's fever-chart trail (ADR-196).
module PlanningDates
  # `count` Fridays ending at the Friday on or before `reference_date`, oldest
  # first.
  def recent_fridays(reference_date, count)
    friday_wday = 5
    days_back = (reference_date.wday - friday_wday) % 7
    most_recent = reference_date - days_back
    (0...count).to_a.reverse.map { |i| most_recent - (7 * i) }
  end
end
