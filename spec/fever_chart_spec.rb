# frozen_string_literal: true

require 'date'
require_relative '../lib/almirah/doc_items/work_item'
require_relative '../lib/almirah/project/fever_chart'

# A minimal stand-in for CriticalChain: the chain rows and the buffer size.
class FakePlan
  attr_reader :chain, :buffer

  def initialize(chain, buffer)
    @chain = chain
    @buffer = buffer
  end
end

# A record whose effort log answers row_actual_hours_on(item, date). The entries
# are [item, date, hours] triples.
class StubRecord
  def initialize(entries)
    @entries = entries
  end

  def row_actual_hours_on(item, date)
    key = item.to_s.downcase
    @entries.select { |i, d, _| i.downcase == key && d <= date }.sum { |_, _, h| h }
  end
end

# Unit coverage for the ADR-196 buffer-consumption fever chart: the
# focused-weighted chain-completion %, the buffer-consumption %, the Done-credits-
# the-live-point rule, the as-of-date trail, and the positive-estimate filter.
# The chain and buffer are supplied directly so the math is exercised without the
# scheduler or any parsing.
RSpec.describe FeverChart do
  def row(activity, focused, status: 'To Do', record: 'ADR-1')
    WorkItem.new(record_id: record, step: 1, activity: activity, owner: 'BA', status: status,
                 depends_on_refs: [], focused_estimate: focused, safe_estimate: focused)
  end

  let(:today) { Date.new(2026, 6, 19) }
  let(:past)  { Date.new(2020, 1, 1) }

  it 'weights chain completion by focused estimate from logged effort' do
    plan = FakePlan.new([row('Analysis', 2), row('Code', 3)], 4)
    # 16h = 2 days fully credits the 2-day Analysis row; Code has no effort.
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', past, 16]]) }
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    completion, consumption = fever.live_point(today)
    expect(completion).to eq(40.0) # 100 * (1*2 + 0*3) / 5
    expect(consumption).to eq(0.0)
  end

  it 'credits a Done row fully at the live point but not on the historical trail' do
    plan = FakePlan.new([row('Analysis', 2, status: 'Done'), row('Code', 3)], 4)
    lookup = { 'ADR-1' => StubRecord.new([]) } # no effort logged at all
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    expect(fever.live_point(today).first).to eq(40.0)  # Done credits via Status
    expect(fever.point_on(today).first).to eq(0.0)     # historical = effort only
  end

  it 'computes buffer consumption as the focused overrun over the buffer and may exceed 100' do
    plan = FakePlan.new([row('Analysis', 2)], 2)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', past, 48]]) } # 6 days vs 2 focused
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    expect(fever.live_point(today).last).to eq(200.0) # 100 * (6-2) / 2
  end

  it 'reports zero consumption for a row under its focused estimate' do
    plan = FakePlan.new([row('Analysis', 2)], 2)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', past, 8]]) } # 1 day < 2 focused
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    expect(fever.live_point(today).last).to eq(0.0)
  end

  it 'clamps a row credit at one even when effort exceeds the estimate' do
    plan = FakePlan.new([row('Analysis', 2)], 2)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', past, 80]]) } # 10 days logged
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    expect(fever.live_point(today).first).to eq(100.0)
  end

  it 'honours the as-of-date so a trail rises as effort accrues' do
    plan = FakePlan.new([row('Analysis', 2)], 2)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', Date.new(2026, 6, 12), 8]]) }
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    early = fever.point_on(Date.new(2026, 6, 5))   # before the entry
    late  = fever.point_on(Date.new(2026, 6, 19))  # after the entry
    expect(early.first).to eq(0.0)
    expect(late.first).to eq(50.0) # 1 of 2 days
  end

  it 'guards a zero buffer, reporting no consumption' do
    plan = FakePlan.new([row('Analysis', 2)], 0)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', past, 80]]) }
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    expect(fever.live_point(today).last).to eq(0.0)
  end

  it 'excludes zero-focused chain rows from completion and is not plottable when none have estimates' do
    plottable = described_class.new(FakePlan.new([row('Analysis', 0)], 0), {}, hours_per_day: 8)
    expect(plottable.plottable?).to be false

    plan = FakePlan.new([row('Analysis', 2), row('Code', 0)], 2)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', past, 16]]) }
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    expect(fever.plottable?).to be true
    expect(fever.live_point(today).first).to eq(100.0) # denom is the 2-day row only
  end

  it 'builds one trail point per supplied date, in order' do
    plan = FakePlan.new([row('Analysis', 2)], 2)
    lookup = { 'ADR-1' => StubRecord.new([['Analysis', Date.new(2026, 6, 12), 16]]) }
    fever = described_class.new(plan, lookup, hours_per_day: 8)
    trail = fever.trail([Date.new(2026, 6, 5), Date.new(2026, 6, 19)])
    expect(trail.map(&:first)).to eq([0.0, 100.0])
  end
end
