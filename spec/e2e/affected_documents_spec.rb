# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Affected Documents', type: :aruba do
  context 'when a decision record has an Affected Documents section' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.

        [REQ-002] A second requirement.
      MD
      write_file('myproject/decisions/adr-300-affecting-req.md', <<~MD)
        ---
        title: "ADR-300: Affects REQ-001 and REQ-002"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A first requirement. | >[REQ-001] |
        | 2 | A second requirement. | >[REQ-002] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Recognises the Affected Documents section and parses its three-column table. >[SRS-052] >[SRS-053] </REQ>
    # <REQ> Req-ID column accepts >[BBB-NNN] reference syntax. >[SRS-054] </REQ>
    # <REQ> Render the Req-ID cell on the Decision page as a clickable link. >[SRS-057] </REQ>
    it 'renders Req-ID cells in the Affected Documents table as links to the Controlled Items' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-300.html')))
      links = doc.css('a.external').select { |a| a['href']&.include?('specifications/req/req.html') }
      hrefs = links.map { |a| a['href'] }
      texts = links.map(&:text).map(&:strip)
      expect(hrefs).to include('./../specifications/req/req.html#REQ-001')
      expect(hrefs).to include('./../specifications/req/req.html#REQ-002')
      expect(texts).to include('REQ-001', 'REQ-002')
    end

    # <REQ> Controlled-paragraph table carries a DR column titled "Decision Record" after COV. >[SRS-058] </REQ>
    it 'renders the DR column header on the specification page after COV' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      headers = doc.css('table.controlled thead th').map { |th| [th.text.strip, th['title']] }
      cov_index = headers.index { |text, _| text == 'COV' }
      dr_index = headers.index { |text, _| text == 'DR' }
      expect(cov_index).not_to be_nil
      expect(dr_index).to eq(cov_index + 1)
      expect(headers[dr_index][1]).to eq('Decision Record')
    end

    # <REQ> Establishes a link from each Affected Documents row to the referenced Item. >[SRS-055] </REQ>
    # <REQ> For each Controlled Item show the affecting Decision Records as clickable links. >[SRS-058] </REQ>
    # <REQ> Click on a decision record link navigates to the Decision Record page. >[SRS-060] </REQ>
    it 'renders a single decision-record link in the DR cell of each affected Controlled Item' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      rows = doc.css('table.controlled tr')
      req1_row = rows.find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
      req2_row = rows.find { |tr| tr.css('td.item_id a[name="REQ-002"]').any? }
      req1_dr = req1_row.css('td').last.css('a').first
      req2_dr = req2_row.css('td').last.css('a').first
      expect(req1_dr.text.strip).to eq('ADR-300')
      expect(req1_dr['href']).to eq('./../../decisions/adr-300.html')
      expect(req2_dr.text.strip).to eq('ADR-300')
      expect(req2_dr['href']).to eq('./../../decisions/adr-300.html')
    end
  end

  context 'when multiple decision records affect the same Controlled Item' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/adr-310-first.md', <<~MD)
        ---
        title: "ADR-310: First"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A first requirement. | >[REQ-001] |
      MD
      write_file('myproject/decisions/adr-311-second.md', <<~MD)
        ---
        title: "ADR-311: Second"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A first requirement (revised). | >[REQ-001] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Multi-link DR cell uses the collapse-to-count widget. >[SRS-059] </REQ>
    it 'collapses the DR cell to a clickable count with an expanded list' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      collapsed = doc.at_css('div#DR_REQ-001 a')
      expanded = doc.css('div#DRS_REQ-001 a')
      expect(collapsed.text.strip).to eq('2')
      expect(collapsed['onclick']).to include('decisionLink_OnClick')
      expanded_texts = expanded.map(&:text).map(&:strip)
      expanded_hrefs = expanded.map { |a| a['href'] }
      expect(expanded_texts).to contain_exactly('ADR-310', 'ADR-311')
      expect(expanded_hrefs).to contain_exactly('./../../decisions/adr-310.html',
                                                './../../decisions/adr-311.html')
    end
  end

  context 'when a decision record has no Affected Documents section' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/adr-320-no-section.md', <<~MD)
        ---
        title: "ADR-320: No Affected Documents Section"
        ---

        ## Context

        A decision with no Affected Documents section.
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> DR column is empty when no decision record affects the Controlled Item. >[SRS-058] </REQ>
    it 'renders the DR column header but with empty DR cells' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      headers = doc.css('table.controlled thead th').map { |th| th.text.strip }
      expect(headers).to include('DR')
      row = doc.css('table.controlled tr').find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
      expect(row.css('td').last.text.strip).to eq('')
    end
  end

  context 'when an Affected Documents row references a non-existing Controlled Item' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/adr-330-broken.md', <<~MD)
        ---
        title: "ADR-330: Broken Reference"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A non-existent requirement. | >[REQ-999] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Broken Req-ID does not crash the build and the decision page is still rendered. >[SRS-056] </REQ>
    it 'still renders the decision page when the Req-ID does not resolve' do
      expect(File.exist?(expand_path('myproject/build/decisions/adr-330.html'))).to be true
    end
  end

  context 'when a decision record has a sample table outside the Affected Documents section' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/adr-350-with-sample.md', <<~MD)
        ---
        title: "ADR-350: With sample table outside the section"
        ---

        # Decision

        Illustrative example of the format used in Affected Documents:

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | sample row used only for illustration | >[REQ-001] |

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A first requirement. | >[REQ-001] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Only tables inside the Affected Documents section establish links. >[SRS-052] >[SRS-055] </REQ>
    it 'ignores sample tables outside the Affected Documents section' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      row = doc.css('table.controlled tr').find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
      dr_cell = row.css('td').last
      single_link = dr_cell.css('a').first
      expect(dr_cell.css('div#DR_REQ-001').any?).to be false
      expect(single_link.text.strip).to eq('ADR-350')
      expect(single_link['href']).to eq('./../../decisions/adr-350.html')
    end
  end

  context 'when an Affected Documents row cell contains a backslash-escaped pipe' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/adr-360-escaped-pipe.md', <<~MD)
        ---
        title: "ADR-360: Escaped pipe in Proposed Text"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | Support an alias `[[target\\|display text]]` rendering the display text. | >[REQ-001] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A backslash-escaped pipe inside a cell is a literal "|", not a column separator. >[SRS-052] </REQ>
    it 'keeps the row at three columns and renders the literal pipe' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-360.html')))
      data_row = doc.css('table tr').find { |tr| tr.css('td a[name="adr-360.1"]').any? }
      expect(data_row).not_to be_nil
      expect(data_row.css('td').length).to eq(3)
      code = data_row.css('td code.inline').first
      expect(code.text).to eq('[[target|display text]]')
      ref_link = data_row.css('td').last.css('a').first
      expect(ref_link.text.strip).to eq('REQ-001')
    end
  end

  context 'when a decision record lives in a nested subfolder' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/issues/issue-340-nested.md', <<~MD)
        ---
        title: "ISSUE-340: Nested"
        ---

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | A first requirement. | >[REQ-001] |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Nested-folder decision page resolves Req-ID hrefs with correct relative depth. >[SRS-057] </REQ>
    it 'renders the Req-ID link with the correct relative path from a nested decision page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/issues/issue-340.html')))
      link = doc.css('a.external').find { |a| a['href']&.include?('REQ-001') }
      expect(link['href']).to eq('./../../specifications/req/req.html#REQ-001')
    end

    # <REQ> DR cell on the specification page resolves to a nested decision page. >[SRS-060] </REQ>
    it 'renders the DR cell href pointing at the nested decision page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      row = doc.css('table.controlled tr').find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
      dr_link = row.css('td').last.css('a').first
      expect(dr_link.text.strip).to eq('ISSUE-340')
      expect(dr_link['href']).to eq('./../../decisions/issues/issue-340.html')
    end
  end
end
