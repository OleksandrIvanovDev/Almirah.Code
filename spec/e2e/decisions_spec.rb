# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Decision Records', type: :aruba do
  context 'when the project has decision records' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      write_file('myproject/decisions/adr-001-foo.md', <<~MD)
        ---
        title: "ADR-001: First Decision"
        ---

        ## Context

        A first decision.
      MD
      write_file('myproject/decisions/adr-002-bar.md', <<~MD)
        ---
        title: "ADR-002: Second Decision"
        ---

        ## Context

        A second decision.
      MD
      write_file('myproject/decisions/README.txt', 'ignored non-markdown file')
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Provide a Decision Records Overview page with Sequence Number, Type, Title columns. >[SRS-041] </REQ>
    it 'renders build/decisions/overview.html' do
      expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be true
    end

    # <REQ> ID derived from filename letters-digits prefix; full stem when no match. >[SRS-040] </REQ>
    # <REQ> Provide a Decision Records Overview page with Sequence Number, Type, Title columns. >[SRS-041] </REQ>
    # <REQ> Sequence Number is the digits portion of the ID. >[SRS-044] </REQ>
    # <REQ> Type is the letters portion of the ID, in upper case. >[SRS-045] </REQ>
    # <REQ> Title comes from the YAML frontmatter title field. >[SRS-046] </REQ>
    it 'lists all parsed decision records on the overview page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      sequence_numbers = doc.xpath('//td[@class="item_id"]').map { |c| c.text.strip }
      anchor_ids = doc.xpath('//td[@class="item_id"]//a').map { |a| a['id'] }
      types = doc.xpath('//td[@class="item_type"]').map { |c| c.text.strip }
      titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
      expect(sequence_numbers).to contain_exactly('001', '002')
      expect(anchor_ids).to contain_exactly('adr-001', 'adr-002')
      expect(types).to contain_exactly('ADR', 'ADR')
      expect(titles).to contain_exactly('ADR-001: First Decision', 'ADR-002: Second Decision')
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'adds the Decision Records link to the index page top-nav' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/index.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('./decisions/overview.html')
      expect(link.text).to include('Decision Records')
      expect(link.at_css('i')['class']).to include('fa-gavel')
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'adds the Decision Records link to specification page top-nav with correct relative path' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('./../../decisions/overview.html')
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'adds the Decision Records link to the overview page itself' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('./overview.html')
    end

    # <REQ> Render each decision record to an HTML page named after the Decision Record ID. >[SRS-047] </REQ>
    it 'renders an HTML page per decision using the id as the filename' do
      expect(File.exist?(expand_path('myproject/build/decisions/adr-001.html'))).to be true
      expect(File.exist?(expand_path('myproject/build/decisions/adr-002.html'))).to be true
    end

    # <REQ> Render each decision record to an HTML page named after the Decision Record ID. >[SRS-047] </REQ>
    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'sets correct CSS/JS and top-nav paths on top-level decision pages' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-001.html')))
      css_hrefs = doc.css('link[rel="stylesheet"]').map { |l| l['href'] }
      js_srcs   = doc.css('script[src]').map { |s| s['src'] }
      expect(css_hrefs).to include('../css/main.css')
      expect(js_srcs).to include('../scripts/main.js')
      expect(doc.at_css('#index_menu_item')['href']).to eq('../index.html')
      expect(doc.at_css('#decisions_menu_item')['href']).to eq('../decisions/overview.html')
    end

    # <REQ> Title click in the overview navigates to the rendered decision page. >[SRS-042] </REQ>
    it 'links each overview title to the rendered decision page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      hrefs = doc.xpath('//td[@class="item_text"]/a').map { |a| a['href'] }
      expect(hrefs).to contain_exactly('./adr-001.html', './adr-002.html')
    end
  end

  context 'when a decision record lives in a nested folder' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/decisions/enhancements/adr-200-nested.md', <<~MD)
        ---
        title: "ADR-200: A nested decision"
        ---

        body
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Accept decision records placed in the decisions/ folder, including nested subfolders. >[SRS-043] </REQ>
    # <REQ> Render each decision record to an HTML page named after the Decision Record ID. >[SRS-047] </REQ>
    it 'mirrors the source folder structure in build/decisions' do
      expect(File.exist?(expand_path('myproject/build/decisions/enhancements/adr-200.html'))).to be true
    end

    # <REQ> Accept decision records placed in the decisions/ folder, including nested subfolders. >[SRS-043] </REQ>
    # <REQ> Render each decision record to an HTML page named after the Decision Record ID. >[SRS-047] </REQ>
    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'sets CSS/JS and top-nav paths relative to the nested depth' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/enhancements/adr-200.html')))
      css_hrefs = doc.css('link[rel="stylesheet"]').map { |l| l['href'] }
      js_srcs   = doc.css('script[src]').map { |s| s['src'] }
      expect(css_hrefs).to include('../../css/main.css')
      expect(js_srcs).to include('../../scripts/main.js')
      expect(doc.at_css('#index_menu_item')['href']).to eq('../../index.html')
      expect(doc.at_css('#decisions_menu_item')['href']).to eq('../../decisions/overview.html')
    end

    # <REQ> Title click in the overview navigates to the rendered decision page. >[SRS-042] </REQ>
    # <REQ> Accept decision records placed in the decisions/ folder, including nested subfolders. >[SRS-043] </REQ>
    it 'links the overview title to the nested rendered page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      hrefs = doc.xpath('//td[@class="item_text"]/a').map { |a| a['href'] }
      expect(hrefs).to eq(['./enhancements/adr-200.html'])
    end
  end

  context 'when a decision record has no frontmatter title' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/decisions/adr-001-titleless.md', "body without frontmatter or heading\n")
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> ID derived from filename letters-digits prefix; full stem when no match. >[SRS-040] </REQ>
    # <REQ> Sequence Number is the digits portion of the ID. >[SRS-044] </REQ>
    # <REQ> Type is the letters portion of the ID, in upper case. >[SRS-045] </REQ>
    it 'derives the id from the letters-digits prefix and falls back to <id>.md for the title' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      sequence_numbers = doc.xpath('//td[@class="item_id"]').map { |c| c.text.strip }
      anchor_ids = doc.xpath('//td[@class="item_id"]//a').map { |a| a['id'] }
      types = doc.xpath('//td[@class="item_type"]').map { |c| c.text.strip }
      titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
      expect(sequence_numbers).to eq(['001'])
      expect(anchor_ids).to eq(['adr-001'])
      expect(types).to eq(['ADR'])
      expect(titles).to eq(['adr-001.md'])
    end
  end

  context 'when a decision record filename has no descriptive suffix' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/decisions/ise-1892.md', <<~MD)
        ---
        title: "ISE-1892: A redmine-style record"
        ---

        body
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> ID derived from filename letters-digits prefix; full stem when no match. >[SRS-040] </REQ>
    # <REQ> Sequence Number is the digits portion of the ID. >[SRS-044] </REQ>
    # <REQ> Type is the letters portion of the ID, in upper case. >[SRS-045] </REQ>
    # <REQ> Title comes from the YAML frontmatter title field. >[SRS-046] </REQ>
    it 'uses the full letters-digits stem as the id and shows the digits in the # column' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      sequence_numbers = doc.xpath('//td[@class="item_id"]').map { |c| c.text.strip }
      anchor_ids = doc.xpath('//td[@class="item_id"]//a').map { |a| a['id'] }
      types = doc.xpath('//td[@class="item_type"]').map { |c| c.text.strip }
      titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
      expect(sequence_numbers).to eq(['1892'])
      expect(anchor_ids).to eq(['ise-1892'])
      expect(types).to eq(['ISE'])
      expect(titles).to eq(['ISE-1892: A redmine-style record'])
    end
  end

  context 'when a decision record has both frontmatter title and an H1' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/decisions/adr-042-precedence.md', <<~MD)
        ---
        title: "From Frontmatter"
        ---

        # Different H1 In Body

        body
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Title comes from the YAML frontmatter title field. >[SRS-046] </REQ>
    it 'uses the frontmatter title rather than the H1' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
      expect(titles).to eq(['From Frontmatter'])
    end
  end

  context 'when a decision record filename does not match the convention' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/decisions/meeting-notes.md', <<~MD)
        # Meeting notes

        body
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> ID derived from filename letters-digits prefix; full stem when no match. >[SRS-040] </REQ>
    # <REQ> Type is the letters portion of the ID, in upper case. >[SRS-045] </REQ>
    it 'falls back to the full filename stem as the id and as the # column label, with empty Type' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      sequence_numbers = doc.xpath('//td[@class="item_id"]').map { |c| c.text.strip }
      anchor_ids = doc.xpath('//td[@class="item_id"]//a').map { |a| a['id'] }
      types = doc.xpath('//td[@class="item_type"]').map { |c| c.text.strip }
      expect(sequence_numbers).to eq(['meeting-notes'])
      expect(anchor_ids).to eq(['meeting-notes'])
      expect(types).to eq([''])
    end
  end

  context 'when the project has no decision records' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      run_command_and_stop('almirah please myproject')
    end

    it 'does not create build/decisions/overview.html' do
      expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be false
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'does not add the Decision Records link to the index page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/index.html')))
      expect(doc.at_css('#decisions_menu_item')).to be_nil
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'does not add the Decision Records link to spec pages' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      expect(doc.at_css('#decisions_menu_item')).to be_nil
    end
  end

  context 'when a decision record has a single "*" current-status marker' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-300-marked.md', <<~MD)
        ---
        title: "ADR-300: Marked Record"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 17-05-2026 | Proposed |
        | * | 17-05-2026 | Accepted |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Decision Record current status comes from the "*"-marked row of the Status table. >[SRS-049] </REQ>
    # <REQ> Decision Records Overview page has a Status column between Type and Title. >[SRS-051] </REQ>
    it 'shows the marked row status value in the overview Status column' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      statuses = doc.xpath('//td[@class="item_status"]').map { |c| c.text.strip }
      expect(statuses).to eq(['Accepted'])
    end

    # <REQ> Decision Records Overview page has a Status column between Type and Title. >[SRS-051] </REQ>
    it 'places the Status column between Type and Title in the overview' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      table_xpath = '//table[contains(concat(" ", @class, " "), " controlled ")]/thead/th'
      header_cells = doc.xpath(table_xpath).map { |th| th.text.strip }
      expect(header_cells).to eq(['#', 'Type', 'Status', 'Title', 'Start Date', 'Target Date', 'Release', 'Owner'])
    end

    # <REQ> Render the "*" in the Status table marker column as "▶" in the rendered HTML. >[SRS-050] </REQ>
    it 'renders the marker as ▶ in the decision page Status table' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-300.html')))
      status_table = doc.css('table.markdown_table').first
      first_column_cells = status_table.css('tr').map { |tr| tr.css('td').first&.text&.strip }.compact
      expect(first_column_cells).to include('▶')
      expect(first_column_cells).not_to include('*')
    end

    # <REQ> Highlight the current-status row in the Status table for visual emphasis. >[SRS-050] </REQ>
    it 'tags the marked row with the current_status class so CSS can highlight it' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-300.html')))
      status_table = doc.css('table.markdown_table').first
      marked_rows = status_table.css('tr.current_status')
      expect(marked_rows.length).to eq(1)
      expect(marked_rows.first.css('td').first.text.strip).to eq('▶')
      unmarked_rows = status_table.css('tr:not(.current_status)')
      expect(unmarked_rows.any? { |tr| tr.css('td').first&.text&.include?('▶') }).to be false
    end
  end

  context 'when a decision record has no current-status marker' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-301-unmarked.md', <<~MD)
        ---
        title: "ADR-301: Unmarked Record"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 17-05-2026 | Proposed |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Current status is undefined when zero rows carry the marker. >[SRS-049] </REQ>
    # <REQ> Decision Records Overview Status cell is empty when current status is undefined. >[SRS-051] </REQ>
    it 'leaves the overview Status cell empty' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      statuses = doc.xpath('//td[@class="item_status"]').map { |c| c.text.strip }
      expect(statuses).to eq([''])
    end
  end

  context 'when a decision record has multiple current-status markers' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-302-multi.md', <<~MD)
        ---
        title: "ADR-302: Multi-Marker Record"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 17-05-2026 | Proposed |
        | * | 17-05-2026 | Accepted |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Current status is undefined when more than one row carries the marker. >[SRS-049] </REQ>
    # <REQ> Decision Records Overview Status cell is empty when current status is undefined. >[SRS-051] </REQ>
    it 'leaves the overview Status cell empty' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      statuses = doc.xpath('//td[@class="item_status"]').map { |c| c.text.strip }
      expect(statuses).to eq([''])
    end
  end

  context 'when a decision record has "*" in a non-Status table' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-303-other-tables.md', <<~MD)
        ---
        title: "ADR-303: Marker In Non-Status Table"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 17-05-2026 | Accepted |

        # Scope

        | Item | Status | Note |
        |---|---|---|
        | Code | Done | * |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Triangle substitution applies only to the Status table. >[SRS-050] </REQ>
    it 'does not substitute "*" outside the Status table' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-303.html')))
      tables = doc.css('table.markdown_table')
      status_first_col = tables[0].css('tr').map { |tr| tr.css('td').first&.text&.strip }.compact
      scope_cells = tables[1].css('td').map { |td| td.text.strip }
      expect(status_first_col).to include('▶')
      expect(scope_cells).to include('*')
      expect(scope_cells).not_to include('▶')
    end
  end

  context 'when a decision record has dates in both Status and Scope tables' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-400-both.md', <<~MD)
        ---
        title: "ADR-400: Earliest Wins"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 15-05-2026 | Proposed |
        | * | 17-05-2026 | Accepted |

        # Scope

        | Item | Status | Start Date | Target Date | Description |
        |---|---|---|---|---|
        | Code | Proposed | 10-05-2026 |  | Earlier work |
        | Tests | Proposed | 20-05-2026 |  | Later work |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Start Date is the earliest of Status Date and Scope Start Date columns. >[SRS-061] </REQ>
    # <REQ> Start Date is rendered in the existing Start Date column, DD-MM-YYYY. >[SRS-065] </REQ>
    it 'picks the earliest date across both tables and renders it on the overview' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-400"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells.first).to eq('10-05-2026')
    end
  end

  context 'when a decision record has no Scope table' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-401-status-only.md', <<~MD)
        ---
        title: "ADR-401: Status Only"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 12-05-2026 | Proposed |
        |   | 18-05-2026 | Accepted |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Falls back to Status Date column when Scope is missing. >[SRS-061] </REQ>
    it 'uses the earliest Status table date' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-401"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells.first).to eq('12-05-2026')
    end
  end

  context 'when a decision record has no Status table but has a Scope table' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-402-scope-only.md', <<~MD)
        ---
        title: "ADR-402: Scope Only"
        ---

        # Scope

        | Item | Status | Start Date | Target Date | Description |
        |---|---|---|---|---|
        | Code | Proposed | 09-05-2026 |  | Work |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Falls back to Scope Start Date column when Status is missing. >[SRS-061] </REQ>
    it 'uses the Scope Start Date column' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-402"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells.first).to eq('09-05-2026')
    end
  end

  context 'when neither table has a parseable date' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-403-nodates.md', <<~MD)
        ---
        title: "ADR-403: No Parseable Dates"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | TBD | Proposed |

        # Scope

        | Item | Status | Start Date | Target Date | Description |
        |---|---|---|---|---|
        | Code | Proposed |  |  | Free text |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Start Date is undefined when no date is parseable. >[SRS-064] </REQ>
    # <REQ> Start Date cell is empty when the attribute is undefined. >[SRS-065] </REQ>
    it 'leaves the Start Date cell empty without raising' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-403"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells.first).to eq('')
    end
  end

  context 'when the Scope table has its columns in a non-default order' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-404-reordered.md', <<~MD)
        ---
        title: "ADR-404: Reordered Columns"
        ---

        # Scope

        | Description | Start Date | Item | Status |
        |---|---|---|---|
        | Free text | 07-05-2026 | Code | Proposed |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Columns are identified by header text, not by position. >[SRS-063] </REQ>
    it 'reads the Start Date column by header text regardless of position' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-404"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells.first).to eq('07-05-2026')
    end
  end

  context 'when a decision record has no dated tables at all' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-405-bare.md', <<~MD)
        ---
        title: "ADR-405: Bare Record"
        ---

        body without status or scope
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Start Date is undefined when neither table is present. >[SRS-064] </REQ>
    it 'leaves the Start Date cell empty' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-405"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells.first).to eq('')
    end
  end

  context 'when a decision record has a Software Versions section with a Target Release Version row' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-500-versioned.md', <<~MD)
        ---
        title: "ADR-500: Versioned Record"
        ---

        # Software Versions

        | Software Version Category | Software Version ID |
        |---|---|
        | Latest Released Version | 0.3.1 |
        | Issue Found in Version | 0.4.0 |
        | Target Release Version | 0.4.0 |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Expose Target Release Version attribute on each Decision Record. >[SRS-066] </REQ>
    # <REQ> Render the Target Release Version attribute in the Release column. >[SRS-070] </REQ>
    it 'renders the Target Release Version value in the Release column' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-500"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[2]).to eq('0.4.0')
    end

    # <REQ> Release column header carries title="Target Release Version". >[SRS-070] </REQ>
    it 'tags the Release header with a Target Release Version title attribute' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      headers = doc.xpath('//table[contains(concat(" ", @class, " "), " controlled ")]/thead/th')
      release_header = headers.find { |th| th.text.strip == 'Release' }
      expect(release_header).not_to be_nil
      expect(release_header['title']).to eq('Target Release Version')
    end

    # <REQ> Release column is placed between Target Date and Owner. >[SRS-070] </REQ>
    it 'places Release between Target Date and Owner in the overview' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      header_cells = doc.xpath('//table[contains(concat(" ", @class, " "), " controlled ")]/thead/th').map { |th| th.text.strip }
      release_index = header_cells.index('Release')
      expect(header_cells[release_index - 1]).to eq('Target Date')
      expect(header_cells[release_index + 1]).to eq('Owner')
    end
  end

  context 'when the Software Versions table has columns in a non-default order' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-501-reordered.md', <<~MD)
        ---
        title: "ADR-501: Reordered Software Versions"
        ---

        # Software Versions

        | Software Version ID | Software Version Category |
        |---|---|
        | 0.3.1 | Latest Released Version |
        | 0.5.0 | Target Release Version |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Columns identified by header text, not by position. >[SRS-067] </REQ>
    it 'reads the Software Version ID column by header text regardless of position' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-501"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[2]).to eq('0.5.0')
    end
  end

  context 'when a decision record has no Software Versions section' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-502-no-versions.md', <<~MD)
        ---
        title: "ADR-502: No Software Versions"
        ---

        body without a Software Versions section
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Target Release Version is undefined when section is missing. >[SRS-069] </REQ>
    # <REQ> Release cell is empty when attribute is undefined. >[SRS-070] </REQ>
    it 'leaves the Release cell empty' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-502"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[2]).to eq('')
    end
  end

  context 'when the Software Versions table is missing the Target Release Version row' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-503-no-row.md', <<~MD)
        ---
        title: "ADR-503: Missing Target Row"
        ---

        # Software Versions

        | Software Version Category | Software Version ID |
        |---|---|
        | Latest Released Version | 0.3.1 |
        | Issue Found in Version | 0.4.0 |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Target Release Version is undefined when the row is missing. >[SRS-069] </REQ>
    it 'leaves the Release cell empty when no Target Release Version row exists' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-503"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[2]).to eq('')
    end
  end

  context 'when the Target Release Version cell is empty' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-504-empty-cell.md', <<~MD)
        ---
        title: "ADR-504: Empty Target Release Version"
        ---

        # Software Versions

        | Software Version Category | Software Version ID |
        |---|---|
        | Latest Released Version | 0.3.1 |
        | Target Release Version |  |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Target Release Version is undefined when the cell is empty. >[SRS-069] </REQ>
    it 'leaves the Release cell empty when the source cell is empty' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-504"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[2]).to eq('')
    end
  end

  context 'when the Target Release Version value is non-SemVer free text' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-505-freeform.md', <<~MD)
        ---
        title: "ADR-505: Freeform Version Value"
        ---

        # Software Versions

        | Software Version Category | Software Version ID |
        |---|---|
        | Target Release Version | n/a |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Version value is passed through verbatim, no SemVer parsing. >[SRS-066] >[SRS-070] </REQ>
    it 'passes free-text values through verbatim' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-505"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[2]).to eq('n/a')
    end
  end
end
