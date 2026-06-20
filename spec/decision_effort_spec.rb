# frozen_string_literal: true

require 'date'
require_relative '../lib/almirah/doc_items/heading'
require_relative '../lib/almirah/doc_items/markdown_table'
require_relative '../lib/almirah/doc_types/decision'

# Unit coverage for the ADR-196 effort readers on Decision: actual_hours,
# actual_hours_on, and the per-row row_actual_hours_on. Tables are built the way
# the parser builds them (the leading pipe stripped before add_row), so the
# header/row alignment matches production without running the full pipeline.
RSpec.describe Decision do
  def stub_doc
    doc = Object.new
    def doc.headings = []
    doc
  end

  def heading(text)
    Heading.new(stub_doc, text, 1)
  end

  # Build a MarkdownTable from full markdown lines, mirroring doc_parser's
  # `row = res[1]` convention (the captured group drops the leading pipe).
  def table(header, *rows)
    md = MarkdownTable.new(stub_doc, header)
    md.is_separator_detected = true
    rows.each { |line| md.add_row(/^[|](.*[|])/.match(line)[1]) }
    md
  end

  def decision_with(*items)
    d = described_class.new('/x/adr-196-effort.md')
    d.instance_variable_set(:@items, items)
    d
  end

  let(:effort_table) do
    table('| Date | Item | Owner | Hours | Note |',
          '| 14-06-2026 | Analysis | BA | 3 | scoping |',
          '| 16-06-2026 | Analysis | BA | 2 | more |',
          '| 18-06-2026 | Code | DEV | 5 | parser |',
          '| 18-06-2026 |  |  | 1 | untagged |')
  end

  subject(:record) { decision_with(heading('Effort'), effort_table) }

  it 'sums all logged hours as the record total, including untagged rows' do
    expect(record.actual_hours).to eq(11.0) # 3 + 2 + 5 + 1
  end

  it 'sums hours dated on or before a given date' do
    expect(record.actual_hours_on(Date.new(2026, 6, 16))).to eq(5.0) # 3 + 2
    expect(record.actual_hours_on(Date.new(2026, 6, 13))).to eq(0.0)
  end

  it 'sums per-row hours by case-insensitive Item match and as-of date' do
    expect(record.row_actual_hours_on('analysis', Date.new(2026, 6, 16))).to eq(5.0)
    expect(record.row_actual_hours_on('Analysis', Date.new(2026, 6, 14))).to eq(3.0)
    expect(record.row_actual_hours_on('Code', Date.new(2026, 6, 18))).to eq(5.0)
    expect(record.row_actual_hours_on('Code', Date.new(2026, 6, 17))).to eq(0.0)
  end

  it 'excludes untagged entries from any per-row total' do
    # The untagged 1h row counts toward actual_hours but no specific Item.
    expect(record.row_actual_hours_on('Analysis', Date.new(2026, 6, 30)) +
           record.row_actual_hours_on('Code', Date.new(2026, 6, 30))).to eq(10.0)
  end

  it 'treats blank, negative, and unparseable Hours as zero' do
    weird = decision_with(heading('Effort'),
                          table('| Date | Item | Hours |',
                                '| 14-06-2026 | Code |  |',
                                '| 15-06-2026 | Code | -4 |',
                                '| 16-06-2026 | Code | abc |',
                                '| 17-06-2026 | Code | 2 |'))
    expect(weird.actual_hours).to eq(2.0)
  end

  it 'returns zero everywhere when there is no Effort section' do
    none = decision_with(heading('Context'))
    expect(none.actual_hours).to eq(0.0)
    expect(none.actual_hours_on(Date.new(2026, 6, 30))).to eq(0.0)
    expect(none.row_actual_hours_on('Code', Date.new(2026, 6, 30))).to eq(0.0)
  end
end
