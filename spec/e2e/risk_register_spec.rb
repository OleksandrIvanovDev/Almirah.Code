# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the risk register table introduced by ADR-216: each registry renders
# to an overview page holding the registry preface followed by a register
# table whose columns are configured per registry under the risks: root of
# project.yml and filled from the records' sections matched by heading text.
RSpec.describe 'Risk Register Table', type: :aruba do
  def register_table(project_html_path)
    doc = Nokogiri::HTML(File.read(expand_path(project_html_path)))
    doc.at_css('table.risk_register')
  end

  def header_cells(table)
    table.css('thead th').map { |th| th.text.strip }
  end

  context 'when a registry is configured with columns and carries a preface' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: product
            columns: [Severity, Occurrence, Mitigation, Status]
      YML
      write_file('myproject/risks/product/overview.md', <<~MD)
        # Product Risks

        The scales in use run from 1 (negligible) to 10 (catastrophic).
      MD
      write_file('myproject/risks/product/prodr-001-data-loss.md', <<~MD)
        ---
        title: "PRODR-001: Data Loss"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 02-07-2026 | Mitigating |

        # Severity

        8

        # Occurrence

        3

        # Mitigation

        Nightly off-site backups.

        # Analysis

        Long analysis prose that stays on the record page.
      MD
      write_file('myproject/risks/product/prodr-002-slow-search.md', <<~MD)
        ---
        title: "PRODR-002: Slow Search"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 03-07-2026 | Identified |

        # Severity

        4
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Each risk registry renders to an overview page. >[SRS-168] </REQ>
    it 'renders build/risks/<registry>/overview.html' do
      expect(File.exist?(expand_path('myproject/build/risks/product/overview.html'))).to be true
    end

    # <REQ> The page holds the preface first, followed by the register table. >[SRS-168] </REQ>
    it 'places the rendered overview.md content before the register table' do
      html = File.read(expand_path('myproject/build/risks/product/overview.html'))
      expect(html).to include('Product Risks')
      expect(html).to include('The scales in use run from 1 (negligible) to 10 (catastrophic).')
      expect(html.index('Product Risks')).to be < html.index('risk_register')
    end

    # <REQ> Implicit leading columns are the linked ID and Title, then the configured columns. >[SRS-168] </REQ>
    it 'renders the implicit columns followed by the configured columns in order' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(header_cells(table)).to eq(['#', 'Title', 'Severity', 'Occurrence', 'Mitigation', 'Status'])
    end

    # <REQ> The ID column shows the uppercased record ID linked to the record page. >[SRS-168] </REQ>
    it 'links each row id to the record page, displayed uppercased' do
      table = register_table('myproject/build/risks/product/overview.html')
      id_links = table.css('td.item_id a')
      expect(id_links.map { |a| a.text.strip }).to eq(%w[PRODR-001 PRODR-002])
      expect(id_links.map { |a| a['href'] }).to eq(['./prodr-001.html', './prodr-002.html'])
    end

    # <REQ> The uppercasing is display-only: the anchor keeps the canonical lowercase id. >[SRS-168] </REQ>
    it 'keeps the lowercase id as the row anchor' do
      table = register_table('myproject/build/risks/product/overview.html')
      id_links = table.css('td.item_id a')
      expect(id_links.map { |a| a['name'] }).to eq(%w[prodr-001 prodr-002])
      expect(id_links.map { |a| a['id'] }).to eq(%w[prodr-001 prodr-002])
    end

    # <REQ> The Title cell drops the record's own leading ID prefix from the frontmatter title. >[SRS-168] </REQ>
    it 'renders the titles without the id prefix, linked to the record pages' do
      table = register_table('myproject/build/risks/product/overview.html')
      title_links = table.css('td.item_text a.external')
      expect(title_links.map { |a| a.text.strip }).to eq(['Data Loss', 'Slow Search'])
      expect(title_links.map { |a| a['href'] }).to eq(['./prodr-001.html', './prodr-002.html'])
    end

    # <REQ> The record page itself keeps the full frontmatter title. >[SRS-168] </REQ>
    it 'keeps the full title on the record page' do
      record_html = File.read(expand_path('myproject/build/risks/product/prodr-001.html'))
      expect(record_html).to include('PRODR-001: Data Loss')
    end

    # <REQ> A cell is the rendered content of the record section whose heading equals the column name. >[SRS-168] </REQ>
    it 'fills the cells from the records sections matched by heading text' do
      table = register_table('myproject/build/risks/product/overview.html')
      first_row_cells = table.css('tr').first.css('td').map { |td| td.text.strip }
      expect(first_row_cells[2]).to eq('8')
      expect(first_row_cells[3]).to eq('3')
      expect(first_row_cells[4]).to eq('Nightly off-site backups.')
    end

    # <REQ> Sections not surfaced as columns stay on the record page only. >[SRS-168] </REQ>
    it 'does not surface unconfigured sections in the register' do
      html = File.read(expand_path('myproject/build/risks/product/overview.html'))
      expect(html).not_to include('Long analysis prose')
      record_html = File.read(expand_path('myproject/build/risks/product/prodr-001.html'))
      expect(record_html).to include('Long analysis prose')
    end

    # <REQ> A record missing a configured section gets an empty cell. >[SRS-168] </REQ>
    it 'renders an empty cell when a record has no matching section' do
      table = register_table('myproject/build/risks/product/overview.html')
      second_row_cells = table.css('tr')[1].css('td').map { |td| td.text.strip }
      expect(second_row_cells[3]).to eq('') # no Occurrence section
      expect(second_row_cells[4]).to eq('') # no Mitigation section
    end

    # <REQ> The Status column is filled from the record's current lifecycle status. >[SRS-168] </REQ>
    it 'fills the Status column from the lifecycle marker, not from a section' do
      table = register_table('myproject/build/risks/product/overview.html')
      statuses = table.css('td.item_status').map { |td| td.text.strip }
      expect(statuses).to eq(%w[Mitigating Identified])
    end
  end

  context 'when a registry has no risks: configuration entry' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: product
            columns: [Severity, Status]
      YML
      write_file('myproject/risks/product/prodr-001-configured.md', <<~MD)
        ---
        title: "Configured Without Prefix"
        ---

        body
      MD
      write_file('myproject/risks/project/prjr-001-unconfigured.md', <<~MD)
        ---
        title: "PRJR-001: Unconfigured"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 05-07-2026 | Identified |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> An unconfigured registry still renders with the implicit columns plus Status only. >[SRS-168] </REQ>
    it 'renders the unconfigured registry with the implicit columns plus Status' do
      table = register_table('myproject/build/risks/project/overview.html')
      expect(header_cells(table)).to eq(['#', 'Title', 'Status'])
      statuses = table.css('td.item_status').map { |td| td.text.strip }
      expect(statuses).to eq(['Identified'])
    end

    # <REQ> Columns are configured per registry. >[SRS-168] </REQ>
    it 'keeps the configured registry on its own column set' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(header_cells(table)).to eq(['#', 'Title', 'Severity', 'Status'])
    end

    # <REQ> A title not starting with the record's own ID renders unchanged. >[SRS-168] </REQ>
    it 'renders a title without the id prefix unchanged, next to the uppercased id' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(table.at_css('td.item_id a').text.strip).to eq('PRODR-001')
      expect(table.at_css('td.item_text a.external').text.strip).to eq('Configured Without Prefix')
    end
  end

  context 'when a registry has no overview.md' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/risks/project/prjr-001-bare.md', <<~MD)
        ---
        title: "PRJR-001: Bare"
        ---

        body
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A registry without a preface still renders; its page starts at the table. >[SRS-168] </REQ>
    it 'renders the registry page starting at the register table' do
      expect(File.exist?(expand_path('myproject/build/risks/project/overview.html'))).to be true
      table = register_table('myproject/build/risks/project/overview.html')
      expect(table).not_to be_nil
      expect(header_cells(table)).to eq(['#', 'Title', 'Status'])
    end
  end

  context 'when the project has no risks folder' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      run_command_and_stop('almirah please myproject')
    end

    it 'renders no registry pages' do
      expect(Dir.exist?(expand_path('myproject/build/risks'))).to be false
    end
  end
end
