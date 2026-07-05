# frozen_string_literal: true

require 'date'
require_relative '../lib/almirah/project/working_calendar'

# Unit coverage for the ADR-205 working calendar: anchoring on the first working
# day, mapping working-day indices to dates across weekends and holidays, and the
# calendar-column run used by the Gantt.
RSpec.describe WorkingCalendar do
  # Mon 22-06-2026 .. that week: Mon 22, Tue 23, Wed 24, Thu 25, Fri 26, Sat 27,
  # Sun 28, Mon 29-06-2026.
  let(:monday) { Date.new(2026, 6, 22) }

  it 'maps consecutive working days within a week one-to-one' do
    cal = described_class.new(anchor: monday)
    expect(cal.date_for(1)).to eq(Date.new(2026, 6, 22))
    expect(cal.date_for(5)).to eq(Date.new(2026, 6, 26)) # Friday
  end

  it 'skips the weekend so the sixth working day is the next Monday' do
    cal = described_class.new(anchor: monday)
    expect(cal.date_for(6)).to eq(Date.new(2026, 6, 29))
  end

  it 'anchors working day 1 on the first working day on or after a weekend anchor' do
    cal = described_class.new(anchor: Date.new(2026, 6, 27)) # Saturday
    expect(cal.date_for(1)).to eq(Date.new(2026, 6, 29))     # Monday
  end

  it 'treats a configured holiday as non-working' do
    cal = described_class.new(anchor: monday, holidays: [Date.new(2026, 6, 24)]) # Wed
    expect(cal.date_for(3)).to eq(Date.new(2026, 6, 25)) # Wed skipped -> Thu
    expect(cal.non_working?(Date.new(2026, 6, 24))).to be true
    expect(cal.working?(Date.new(2026, 6, 23))).to be true
  end

  it 'classifies weekends as non-working' do
    cal = described_class.new(anchor: monday)
    expect(cal.weekend?(Date.new(2026, 6, 27))).to be true  # Saturday
    expect(cal.weekend?(Date.new(2026, 6, 28))).to be true  # Sunday
    expect(cal.weekend?(Date.new(2026, 6, 26))).to be false # Friday
  end

  it 'returns the calendar columns including the interleaved non-working days' do
    cal = described_class.new(anchor: monday)
    cols = cal.columns(6) # Mon..Fri (5 working) span to the 6th working day (next Mon)
    expect(cols.length).to eq(8) # Mon Tue Wed Thu Fri Sat Sun Mon
    expect(cols.first).to eq(Date.new(2026, 6, 22))
    expect(cols.last).to eq(Date.new(2026, 6, 29))
  end

  it 'gives the 0-based column index of a working day across weekends' do
    cal = described_class.new(anchor: monday)
    expect(cal.column_index(1)).to eq(0)
    expect(cal.column_index(5)).to eq(4) # Friday
    expect(cal.column_index(6)).to eq(7) # next Monday, after Sat+Sun
  end

  it 'returns no columns for a non-positive count' do
    expect(described_class.new(anchor: monday).columns(0)).to eq([])
  end

  describe 'business-day axis (ADR-206)' do
    it 'excludes weekend days from the business columns' do
      cal = described_class.new(anchor: monday)
      expect(cal.business_columns(6).map(&:day)).to eq([22, 23, 24, 25, 26, 29]) # no 27/28
    end

    it 'keeps a weekday holiday as a business column' do
      cal = described_class.new(anchor: monday, holidays: [Date.new(2026, 6, 24)]) # Wed
      expect(cal.business_columns(3).map(&:day)).to eq([22, 23, 24, 25]) # Wed24 still a column
    end

    it 'indexes business days with no gap for weekends' do
      cal = described_class.new(anchor: monday)
      expect(cal.business_index(1)).to eq(0)
      expect(cal.business_index(5)).to eq(4) # Friday
      expect(cal.business_index(6)).to eq(5) # next Monday, no weekend columns between
    end

    it 'counts a crossed weekday holiday in the business index' do
      cal = described_class.new(anchor: monday, holidays: [Date.new(2026, 6, 24)])
      expect(cal.business_index(3)).to eq(3) # Mon,Tue,(Wed hol),Thu -> index 3
    end

    it 'identifies Fridays' do
      cal = described_class.new(anchor: monday)
      expect(cal.friday?(Date.new(2026, 6, 26))).to be true
      expect(cal.friday?(Date.new(2026, 6, 25))).to be false
    end
  end
end
