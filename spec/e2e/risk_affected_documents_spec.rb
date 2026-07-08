# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the risk Affected Documents links introduced by ADR-218: a risk
# record's "# Affected Documents" section is parsed as a controlled table with
# requirement uplinks exactly as in decision records, the linked specification
# paragraph gains the record among its downlinks, and the register table's
# Affected Documents column renders only the distinct linked IDs.
RSpec.describe 'Risk Affected Documents', type: :aruba do
  def register_table(project_html_path)
    doc = Nokogiri::HTML(File.read(expand_path(project_html_path)))
    doc.at_css('table.risk_register')
  end

  context 'when a risk record carries valid and dangling Req-IDs' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: product
            columns: [Mitigation, Affected Documents, Status]
      YML
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] The software shall sanitise search input.

        [REQ-002] The software shall log rejected queries.
      MD
      write_file('myproject/risks/product/prodr-001-injection.md', <<~MD)
        ---
        title: "PRODR-001: SQL Injection"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 05-07-2026 | Mitigating |

        # Mitigation

        Parameterised queries everywhere.

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | The software shall sanitise search input. | >[REQ-001] |
        | 2 | The software shall log rejected queries. | >[REQ-002] |
        | 3 | A non-existent requirement. | >[REQ-999] |
      MD
      write_file('myproject/risks/product/prodr-002-no-links.md', <<~MD)
        ---
        title: "PRODR-002: No Document Impact"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 05-07-2026 | Accepted |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The section parses as a controlled table whose Req-ID cells are clickable uplinks. >[SRS-171] </REQ>
    it 'renders the record-page Req-ID cells as links to the controlled paragraphs' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/product/prodr-001.html')))
      hrefs = doc.css('table.markdown_table a.external').map { |a| a['href'] }
      expect(hrefs).to include('./../../specifications/req/req.html#REQ-001')
      expect(hrefs).to include('./../../specifications/req/req.html#REQ-002')
    end

    # <REQ> The linked specification paragraph shows the risk record among its downlinks. >[SRS-171] </REQ>
    it 'adds the risk record to the specification paragraph downlinks' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      row = doc.css('table.controlled tr').find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
      record_link = row.css('a').find { |a| a.text.strip == 'PRODR-001' }
      expect(record_link).not_to be_nil
      expect(record_link['href']).to include('risks/product/prodr-001.html')
    end

    # <REQ> The register cell renders only the distinct linked IDs, each clickable, in row order. >[SRS-171] </REQ>
    it 'renders the register cell as linked IDs without the Proposed Text' do
      table = register_table('myproject/build/risks/product/overview.html')
      row = table.at_css('a[id="prodr-001"]').ancestors('tr').first
      affected_cell = row.css('td')[3] # #, Title, Mitigation, Affected Documents
      links = affected_cell.css('a')
      expect(links.map { |a| a.text.strip }).to eq(%w[REQ-001 REQ-002])
      expect(links.first['href']).to eq('./../../specifications/req/req.html#REQ-001')
      expect(affected_cell.text).not_to include('sanitise search input')
    end

    # <REQ> A dangling Req-ID renders in the existing broken-link style rather than being dropped. >[SRS-171] </REQ>
    it 'renders the dangling ID in the broken-link style' do
      table = register_table('myproject/build/risks/product/overview.html')
      row = table.at_css('a[id="prodr-001"]').ancestors('tr').first
      broken = row.at_css('span.broken_link')
      expect(broken).not_to be_nil
      expect(broken.text.strip).to eq('REQ-999')
    end

    # <REQ> A record without the section is a risk without document impact — an empty cell. >[SRS-171] </REQ>
    it 'renders an empty Affected Documents cell for a record without the section' do
      table = register_table('myproject/build/risks/product/overview.html')
      row = table.at_css('a[id="prodr-002"]').ancestors('tr').first
      expect(row.css('td')[3].text.strip).to eq('')
    end

    # <REQ> Risk links are counted in the console output. >[SRS-171] </REQ>
    it 'reports the risk links in the console output' do
      expect(last_command_started.stdout).to match(/^risk links \.+ 1 ok$/)
    end
  end

  context 'when decision records also link the same paragraph' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A shared requirement.
      MD
      write_file('myproject/decisions/adr-001-first.md', <<~MD)
        ---
        title: "ADR-001: First"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A shared requirement. | >[REQ-001] |
      MD
      write_file('myproject/risks/product/prodr-001-shared.md', <<~MD)
        ---
        title: "PRODR-001: Shared"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A shared requirement. | >[REQ-001] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Decision and risk downlinks coexist, each pointing at its own collection. >[SRS-171] </REQ>
    it 'lists both records as downlinks with collection-correct hrefs' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      row = doc.css('table.controlled tr').find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
      texts_and_hrefs = row.css('a').map { |a| [a.text.strip, a['href']] }
      expect(texts_and_hrefs).to include(['ADR-001', './../../decisions/adr-001.html'])
      expect(texts_and_hrefs).to include(['PRODR-001', './../../risks/product/prodr-001.html'])
    end
  end
end
