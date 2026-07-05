# frozen_string_literal: true

require_relative '../lib/almirah/doc_items/work_item'
require_relative '../lib/almirah/project/critical_chain'

# Unit coverage for the ADR-195 critical-chain / project-buffer computation over
# a single decision group's Scope rows. Work items are constructed directly and
# wired with explicit predecessor/successor edges, so the scheduling, chain
# tracing, and buffer sizing are exercised without parsing.
RSpec.describe CriticalChain do
  def work_item(record:, step:, owner:, focused:, safe: focused, status: 'To Do', seq: 1) # rubocop:disable Metrics/ParameterLists
    WorkItem.new(record_id: record, step:, activity: 'X', owner:, status:,
                 depends_on_refs: [], focused_estimate: focused, safe_estimate: safe,
                 record_sequence: seq)
  end

  # Wire pred -> succ (pred is a predecessor of succ).
  def link(pred, succ)
    succ.add_predecessor(pred, cross_group: false)
    pred.add_successor(succ)
  end

  it 'orders a linear dependency chain and sums its durations' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2)
    b = work_item(record: 'A', step: 2, owner: 'DEV', focused: 3)
    c = work_item(record: 'A', step: 3, owner: 'TEST', focused: 2)
    link(a, b)
    link(b, c)
    cc = described_class.new([a, b, c])
    expect(cc.chain).to eq([a, b, c])
    expect(cc.length).to eq(7)
  end

  it 'serialises two unlinked same-owner rows and chains them in finish order' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2, seq: 1)
    b = work_item(record: 'B', step: 1, owner: 'BA', focused: 3, seq: 2)
    cc = described_class.new([a, b])
    expect(cc.length).to eq(5)
    expect(cc.chain).to eq([b, a])
  end

  it 'runs unlinked different-owner rows in parallel, the longer one being the chain' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2)
    b = work_item(record: 'A', step: 2, owner: 'DEV', focused: 3)
    cc = described_class.new([a, b])
    expect(cc.length).to eq(3)
    expect(cc.chain).to eq([b])
  end

  it 'sizes the buffer as ceil(ratio * aggregated chain safety) with negatives clamped' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2, safe: 4) # +2
    b = work_item(record: 'A', step: 2, owner: 'BA', focused: 3, safe: 6) # +3
    c = work_item(record: 'A', step: 3, owner: 'BA', focused: 1, safe: 0) # clamped to 0
    link(a, b)
    link(b, c)
    cc = described_class.new([a, b, c], buffer_ratio: 0.5)
    expect(cc.chain).to eq([a, b, c])
    expect(cc.buffer).to eq(3) # ceil(0.5 * (2 + 3 + 0)) = ceil(2.5)
  end

  it 'defaults buffer_ratio to 0.5 and honours a custom ratio' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2, safe: 6) # +4
    expect(described_class.new([a]).buffer).to eq(2)                      # ceil(0.5 * 4)
    expect(described_class.new([a], buffer_ratio: 1.0).buffer).to eq(4)
    expect(described_class.new([a], buffer_ratio: 0.25).buffer).to eq(1)  # ceil(1.0)
  end

  it 'excludes Done rows from the chain and length' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2, status: 'Done')
    b = work_item(record: 'A', step: 2, owner: 'BA', focused: 3)
    link(a, b)
    cc = described_class.new([a, b])
    expect(cc.chain).to eq([b])
    expect(cc.length).to eq(3)
  end

  it 'treats a predecessor outside the given set as already available' do
    external = work_item(record: 'X', step: 1, owner: 'BA', focused: 5)
    dependent = work_item(record: 'A', step: 1, owner: 'DEV', focused: 2)
    link(external, dependent)
    cc = described_class.new([dependent]) # external not part of this group
    expect(cc.chain).to eq([dependent])
    expect(cc.length).to eq(2)
  end

  it 'handles decimal focused estimates' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 1.5)
    b = work_item(record: 'A', step: 2, owner: 'BA', focused: 2.5, safe: 3.0)
    link(a, b)
    cc = described_class.new([a, b])
    expect(cc.length).to eq(4.0)  # 1.5 + 2.5
    expect(cc.buffer).to eq(1)    # ceil(0.5 * 0.5)
  end

  it 'reports estimated? by whether any row carries a positive focused estimate' do
    unestimated = work_item(record: 'A', step: 1, owner: 'BA', focused: 0)
    expect(described_class.new([unestimated]).estimated?).to be(false)
    estimated = work_item(record: 'A', step: 1, owner: 'BA', focused: 1)
    expect(described_class.new([estimated]).estimated?).to be(true)
  end

  it 'backfills a short low-priority row into an idle lane gap instead of queueing it' do
    # Three records handed from DEV to TEST, DEV serialised A -> B -> C. TEST
    # idles on days 5..7 between A's and C's tests; B's 1-day test becomes ready
    # on day 6, inside that gap. Having the shortest downstream chain it is
    # placed last -- backfill must still slot it into the gap (days 6..6) rather
    # than behind every other TEST row, keeping it off the chain.
    a_code = work_item(record: 'A', step: 1, owner: 'DEV', focused: 2, seq: 1)
    a_test = work_item(record: 'A', step: 2, owner: 'TEST', focused: 2, seq: 1)
    b_code = work_item(record: 'B', step: 1, owner: 'DEV', focused: 3, seq: 2)
    b_test = work_item(record: 'B', step: 2, owner: 'TEST', focused: 1, seq: 2)
    c_code = work_item(record: 'C', step: 1, owner: 'DEV', focused: 2, seq: 3)
    c_test = work_item(record: 'C', step: 2, owner: 'TEST', focused: 2, seq: 3)
    link(a_code, a_test)
    link(b_code, b_test)
    link(c_code, c_test)
    link(a_code, b_code)
    link(b_code, c_code)
    cc = described_class.new([a_code, a_test, b_code, b_test, c_code, c_test])
    expect(cc.length).to eq(9) # DEV chain 2+3+2 plus C's test; B's test adds nothing
    expect(cc.chain).to eq([a_code, b_code, c_code, c_test])
  end

  it 'produces the same chain on repeated computation' do
    a = work_item(record: 'A', step: 1, owner: 'BA', focused: 2, seq: 1)
    b = work_item(record: 'B', step: 1, owner: 'BA', focused: 3, seq: 2)
    c = work_item(record: 'C', step: 1, owner: 'DEV', focused: 4, seq: 3)
    expect(described_class.new([a, b, c]).chain).to eq(described_class.new([a, b, c]).chain)
  end
end
