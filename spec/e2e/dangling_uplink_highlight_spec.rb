# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the dangling-reference highlight (ENH-225): a controlled-table Req-ID
# cell whose uplink references a controlled paragraph missing from an existing
# specification renders with the wrong-links red background and the broken-link
# style, the link staying clickable; and the protocol crash fix (ISSUE-226):
# a protocol with such a dangling Req-ID builds instead of aborting. Each
# example is linked to the requirement it verifies via a
# "<REQ> ... >[SRS-NNN] </REQ>" comment.
RSpec.describe 'dangling uplink highlight', type: :aruba do
  before do
    write_file('myproject/project.yml', "specifications:\n  input: []\n")

    write_file('myproject/specifications/aaa/aaa.md', <<~MD)
      # AAA Specification

      [AAA-001] A requirement that exists.
    MD

    write_file('myproject/decisions/relx/adr-800-sample.md', <<~MD)
      ---
      title: "ADR-800: Sample"
      ---

      # Status

      |  | Date | Status |
      |:---:|---|---|
      | * | 01-01-2025 | Accepted |

      # Affected Documents

      | # | Proposed Text | Req-ID |
      |---|---|---|
      | 1 | Amends an existing requirement. | >[AAA-001] |
      | 2 | States a requirement not written yet. | >[AAA-999] |
      | 3 | One resolved and one pending reference. | >[AAA-001], >[AAA-998] |
    MD

    write_file('myproject/tests/protocols/tp-800/tp-800.md', <<~MD)
      # Test Protocol 800

      | Test Step | Description | Expected Output | Actual Output | Result | Req-ID |
      |---|---|---|---|---|---|
      | 1 | Check the existing item | ok |  |  | >[AAA-001] |
      | 2 | Check the missing item | ok |  |  | >[AAA-999] |
    MD

    run_command_and_stop('almirah please myproject', fail_on_error: false)
  end

  def page(rel)
    Nokogiri::HTML(File.read(expand_path("myproject/build/#{rel}")))
  end

  def req_cell(doc, link_text)
    doc.css('td').find { |td| td.css('a').any? { |a| a.text.strip == link_text } }
  end

  # <REQ> A dangling single-uplink Req-ID cell gets the wrong-links red background. >[SRS-175] </REQ>
  it 'highlights the cell of a dangling reference red' do
    cell = req_cell(page('decisions/relx/adr-800.html'), 'AAA-999')
    expect(cell['style']).to include('background-color: #fcc;')
  end

  # <REQ> The dangling reference takes the broken-link style with an explanatory tooltip, keeping its link clickable. >[SRS-175] </REQ>
  it 'renders the dangling reference as a broken-link styled clickable link' do
    link = page('decisions/relx/adr-800.html').css('a').find { |a| a.text.strip == 'AAA-999' }
    expect(link['class']).to include('broken_link')
    expect(link['title']).to eq('Linked item does not exist')
    expect(link['href']).to end_with('aaa/aaa.html#AAA-999')
  end

  # <REQ> A resolved reference renders exactly as before: no highlight, no broken-link style. >[SRS-175] </REQ>
  it 'renders a resolved reference unchanged' do
    doc = page('decisions/relx/adr-800.html')
    cell = req_cell(doc, 'AAA-001')
    expect(cell['style']).not_to include('background-color')
    link = cell.css('a').first
    expect(link['class']).to eq('external')
    expect(link['title']).to eq('Linked to')
  end

  # <REQ> A multi-uplink cell is highlighted when any reference dangles, flagging only the dangling ones. >[SRS-175] </REQ>
  it 'highlights a multi-uplink cell and flags only the dangling reference' do
    doc = page('decisions/relx/adr-800.html')
    cell = req_cell(doc, 'AAA-998')
    expect(cell['style']).to include('background-color: #fcc;')
    dangling = cell.css('a').find { |a| a.text.strip == 'AAA-998' }
    resolved = cell.css('a').find { |a| a.text.strip == 'AAA-001' }
    expect(dangling['class']).to include('broken_link')
    expect(resolved['class']).not_to include('broken_link')
  end

  # <REQ> A protocol with a dangling Req-ID builds instead of crashing, and its cell carries the same highlight. >[SRS-175] </REQ>
  it 'builds a protocol with a dangling Req-ID and highlights its cell' do
    expect(exist?('myproject/build/tests/protocols/tp-800/tp-800.html')).to be true
    doc = page('tests/protocols/tp-800/tp-800.html')
    expect(req_cell(doc, 'AAA-999')['style']).to include('background-color: #fcc;')
    expect(req_cell(doc, 'AAA-001')['style']).not_to include('background-color')
  end
end
