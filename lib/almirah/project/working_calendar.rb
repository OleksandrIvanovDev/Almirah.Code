# frozen_string_literal: true

require 'date'
require 'set'

# Projects the working-day planning axis (ADR-198 / ADR-195) onto real calendar
# dates (ADR-205). Working day 1 is the first working date on or after the anchor;
# Saturdays, Sundays, and any configured holiday are non-working — skipped when
# counting working days, but still occupying calendar columns. This is a pure
# projection: it never changes the schedule, the chain, or the buffer.
class WorkingCalendar
  SATURDAY = 6
  SUNDAY = 0

  def initialize(anchor: Date.today, holidays: [])
    @holidays = holidays.to_set
    @start = first_working_on_or_after(anchor)
  end

  # The calendar date of the n-th working day (1-based) counted from the anchor.
  def date_for(working_day)
    return @start if working_day <= 1

    date = @start
    remaining = working_day - 1
    while remaining.positive?
      date += 1
      remaining -= 1 if working?(date)
    end
    date
  end

  # Every calendar date from working day 1 through the working_day_count-th working
  # day inclusive, including the non-working dates in between. Empty for a count
  # below 1.
  def columns(working_day_count)
    return [] if working_day_count < 1

    (@start..date_for(working_day_count)).to_a
  end

  # The 0-based calendar column index of the n-th working day within columns.
  def column_index(working_day)
    (date_for(working_day) - @start).to_i
  end

  def working?(date)
    !non_working?(date)
  end

  def non_working?(date)
    weekend?(date) || @holidays.include?(date)
  end

  def weekend?(date)
    [SATURDAY, SUNDAY].include?(date.wday)
  end

  private

  def first_working_on_or_after(date)
    date += 1 while non_working?(date)
    date
  end
end
