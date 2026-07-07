# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the risk record collection introduced by ADR-215: records are
# collected from the first-level subfolders (registries) of risks/, ids are
# derived from filenames, each record renders to its own page, and the current
# status comes from the Status-table "*" marker as for decision records.
RSpec.describe 'Risk Records', type: :aruba do
  context 'when the project has risk records in two registries' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/risks/project/prjr-001-expertise-loss.md', <<~MD)
        ---
        title: "PRJR-001: Expertise Loss"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 01-07-2026 | Identified |
        | * | 05-07-2026 | Mitigating |

        # Description

        A key contributor may leave the project.
      MD
      write_file('myproject/risks/project/prjr-002-budget-cut.md', <<~MD)
        ---
        title: "PRJR-002: Budget Cut"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-07-2026 | Identified |
      MD
      write_file('myproject/risks/product/prodr-001-data-loss.md', <<~MD)
        ---
        title: "PRODR-001: Data Loss"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 02-07-2026 | Accepted |
      MD
      write_file('myproject/risks/product/overview.md', <<~MD)
        # Product Risks

        The registry preface, not a risk record.
      MD
      write_file('myproject/risks/notes.md', "a file directly under risks/ belongs to no registry\n")
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Risk records are collected from first-level risks/ subfolders and rendered to own pages. >[SRS-166] </REQ>
    it 'renders each risk record to its own page under build/risks/<registry>/' do
      expect(File.exist?(expand_path('myproject/build/risks/project/prjr-001.html'))).to be true
      expect(File.exist?(expand_path('myproject/build/risks/project/prjr-002.html'))).to be true
      expect(File.exist?(expand_path('myproject/build/risks/product/prodr-001.html'))).to be true
    end

    # <REQ> The record id is the letters-digits prefix of the file name. >[SRS-166] </REQ>
    it 'derives the page filename from the letters-digits prefix, dropping the slug' do
      expect(File.exist?(expand_path('myproject/build/risks/project/prjr-001-expertise-loss.html'))).to be false
    end

    # <REQ> A registry's overview.md is a preface, not a risk record. >[SRS-166] </REQ>
    it 'does not collect overview.md as a risk record' do
      expect(last_command_started.stdout).to match(/^parsing risk records \.+ 3 ok$/)
      # the registry page (ADR-216) owns the overview.html path; no record row exists for it
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/product/overview.html')))
      expect(doc.at_css('table.risk_register td.item_id a[id="overview"]')).to be_nil
    end

    # <REQ> Records are collected from first-level subfolders only. >[SRS-166] </REQ>
    it 'ignores a markdown file placed directly under risks/' do
      expect(File.exist?(expand_path('myproject/build/risks/notes.html'))).to be false
    end

    # <REQ> The record page shows the frontmatter title. >[SRS-166] </REQ>
    it 'titles the record page from the YAML frontmatter' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/project/prjr-001.html')))
      expect(doc.at_css('title').text).to include('PRJR-001: Expertise Loss')
      expect(doc.at_css('h1').text).to include('PRJR-001: Expertise Loss')
    end

    # <REQ> Record pages render with the navigation pane and depth-correct asset paths. >[SRS-166] </REQ>
    it 'sets CSS/JS and top-nav paths relative to the registry depth' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/project/prjr-001.html')))
      css_hrefs = doc.css('link[rel="stylesheet"]').map { |l| l['href'] }
      js_srcs   = doc.css('script[src]').map { |s| s['src'] }
      expect(css_hrefs).to include('../../css/main.css')
      expect(js_srcs).to include('../../scripts/main.js')
      expect(doc.at_css('#index_menu_item')['href']).to eq('../../index.html')
    end

    # <REQ> Current status comes from the "*"-marked Status row, as for decision records. >[SRS-167] </REQ>
    it 'marks the current-status row on the record page like a decision record' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/project/prjr-001.html')))
      status_table = doc.css('table.markdown_table').first
      marked_rows = status_table.css('tr.current_status')
      expect(marked_rows.length).to eq(1)
      expect(marked_rows.first.css('td').first.text.strip).to eq('▶')
      expect(marked_rows.first.text).to include('Mitigating')
    end
  end

  context 'when a risk record has no current-status marker' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/risks/project/prjr-001-unmarked.md', <<~MD)
        ---
        title: "PRJR-001: Unmarked"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 01-07-2026 | Identified |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Current status is undefined when no row carries the marker. >[SRS-167] </REQ>
    it 'renders the page with no current-status row highlighted' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/project/prjr-001.html')))
      expect(doc.css('tr.current_status')).to be_empty
    end
  end

  context 'when two registries reuse the same record id' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/risks/project/risk-001-first.md', <<~MD)
        ---
        title: "RISK-001: First"
        ---

        body
      MD
      write_file('myproject/risks/product/risk-001-second.md', <<~MD)
        ---
        title: "RISK-001: Second"
        ---

        body
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A duplicate risk record id is reported at build time. >[SRS-166] </REQ>
    it 'reports the duplicated id naming both files' do
      expect(last_command_started.stdout).to match(/^duplicated risk ids \.+ 1$/)
      expect(last_command_started.stdout)
        .to include('risk-001: risks/product/risk-001-second.md, risks/project/risk-001-first.md')
        .or include('risk-001: risks/project/risk-001-first.md, risks/product/risk-001-second.md')
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

    # <REQ> The risk collection is optional. >[SRS-166] </REQ>
    it 'creates no build/risks folder and still completes the build' do
      expect(Dir.exist?(expand_path('myproject/build/risks'))).to be false
      expect(File.exist?(expand_path('myproject/build/index.html'))).to be true
    end
  end
end
