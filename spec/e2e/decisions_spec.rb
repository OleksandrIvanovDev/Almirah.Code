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
      expect(link['href']).to eq('decisions/overview.html')
      expect(link.text).to include('Decision Records')
      expect(link.at_css('i')['class']).to include('fa-gavel')
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'adds the Decision Records link to specification page top-nav with correct relative path' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('../../decisions/overview.html')
    end

    # <REQ> Top-nav Decision Records link on every rendered page, when at least one record exists. >[SRS-048] </REQ>
    it 'adds the Decision Records link to the overview page itself' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('overview.html')
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
      expect(doc.at_css('#decisions_menu_item')['href']).to eq('overview.html')
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
      expect(doc.at_css('#decisions_menu_item')['href']).to eq('../overview.html')
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

  context 'when a decision record has target dates in both Status and Scope tables' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-410-both.md', <<~MD)
        ---
        title: "ADR-410: Latest Wins"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 15-05-2026 | Proposed |
        | * | 17-05-2026 | Accepted |

        # Scope

        | Item | Status | Start Date | Target Date | Description |
        |---|---|---|---|---|
        | Code | Proposed | 10-05-2026 | 22-05-2026 | Later target |
        | Tests | Proposed | 12-05-2026 | 20-05-2026 | Earlier target |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Target Date is the latest of Status Date and Scope Target Date columns. >[SRS-102] </REQ>
    # <REQ> Target Date is rendered in the existing Target Date column, DD-MM-YYYY. >[SRS-106] </REQ>
    it 'picks the latest date across both tables and renders it on the overview' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-410"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[1]).to eq('22-05-2026')
    end
  end

  context 'when a decision record with no Scope table has only Status dates' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-411-status-only.md', <<~MD)
        ---
        title: "ADR-411: Status Only"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 12-05-2026 | Proposed |
        |   | 18-05-2026 | Accepted |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Falls back to the Status Date column when Scope is missing. >[SRS-102] </REQ>
    it 'uses the latest Status table date' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-411"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[1]).to eq('18-05-2026')
    end
  end

  context 'when a decision record has no Status table but has Scope target dates' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-412-scope-only.md', <<~MD)
        ---
        title: "ADR-412: Scope Only"
        ---

        # Scope

        | Item | Status | Start Date | Target Date | Description |
        |---|---|---|---|---|
        | Code | Proposed | 09-05-2026 | 14-05-2026 | Work |
        | Tests | Proposed | 11-05-2026 | 16-05-2026 | More work |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Falls back to the Scope Target Date column when Status is missing. >[SRS-102] </REQ>
    it 'uses the latest Scope Target Date column value' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-412"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[1]).to eq('16-05-2026')
    end
  end

  context 'when neither table has a parseable target date' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-413-nodates.md', <<~MD)
        ---
        title: "ADR-413: No Parseable Dates"
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

    # <REQ> Target Date is undefined when no date is parseable. >[SRS-105] </REQ>
    # <REQ> Target Date cell is empty when the attribute is undefined. >[SRS-106] </REQ>
    it 'leaves the Target Date cell empty without raising' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-413"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[1]).to eq('')
    end
  end

  context 'when the Scope table has its Target Date column in a non-default order' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-414-reordered.md', <<~MD)
        ---
        title: "ADR-414: Reordered Columns"
        ---

        # Scope

        | Description | Target Date | Item | Start Date |
        |---|---|---|---|
        | Free text | 07-05-2026 | Code | 01-05-2026 |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Columns are identified by header text, not by position. >[SRS-104] </REQ>
    it 'reads the Target Date column by header text regardless of position' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      row = doc.at_xpath('//a[@id="adr-414"]/ancestor::tr')
      cells = row.css('td.item_meta').map { |c| c.text.strip }
      expect(cells[1]).to eq('07-05-2026')
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
      xpath = '//table[contains(concat(" ", @class, " "), " controlled ")]/thead/th'
      header_cells = doc.xpath(xpath).map { |th| th.text.strip }
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

  # --- Velocity chart (ADR-182) -----------------------------------------------
  #
  # The chart shows record counts per status as of each of the last 6 Fridays.
  # Tests use fixture dates safely in the past (2024) so records reliably appear
  # in every bar regardless of when the suite is run.

  def velocity_data_block(html)
    block = html[/decisions_velocity_bar.*?data:\s*(\{.*?\}),\s*options:/m, 1]
    JSON.parse(block)
  end

  context 'when the project has decision records with dated Status tables' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-600-old-impl.md', <<~MD)
        ---
        title: "ADR-600: Implemented Long Ago"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 01-01-2024 | Proposed |
        |   | 02-01-2024 | Accepted |
        | * | 03-01-2024 | Implemented |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Velocity chart placed in the second chart cell. >[SRS-071] </REQ>
    it 'emits a stacked bar chart in the second chart cell' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(html).to include('id="decisions_velocity_bar"')
      expect(html).to include("type: 'bar'")
      expect(html).to match(/x:\s*\{\s*stacked:\s*true\s*\}/)
      expect(html).to match(/y:\s*\{\s*stacked:\s*true/)
    end

    # <REQ> Six bars, Fridays ordered oldest-to-newest, DD-MM-YYYY labels. >[SRS-072] </REQ>
    it 'renders six DD-MM-YYYY labels, 7 days apart, ending with the most recent Friday on or before today' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      labels = data['labels']
      expect(labels.length).to eq(6)
      labels.each { |l| expect(l).to match(/\A\d{2}-\d{2}-\d{4}\z/) }
      dates = labels.map { |l| Date.strptime(l, '%d-%m-%Y') }
      dates.each_cons(2) { |a, b| expect(b - a).to eq(7) }
      expect(dates.last.wday).to eq(5)
      expect(dates.last).to be <= Date.today
      expect(Date.today - dates.last).to be < 7
    end

    # <REQ> Status as of date = latest parseable date <= date. >[SRS-073] </REQ>
    it 'classifies an old fully-Implemented record as Implemented in every bar' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      implemented = data['datasets'].find { |d| d['label'] == 'Implemented' }
      expect(implemented).not_to be_nil
      expect(implemented['data']).to eq([1, 1, 1, 1, 1, 1])
    end
  end

  context 'when a decision record is dated in the future' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-601-future.md', <<~MD)
        ---
        title: "ADR-601: Not Yet Proposed"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2030 | Proposed |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Record not yet proposed contributes to no bar. >[SRS-074] </REQ>
    it 'contributes to no bar when its earliest date is after every Friday in the window' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      totals = Array.new(data['labels'].length, 0)
      data['datasets'].each do |ds|
        ds['data'].each_with_index { |v, i| totals[i] += v }
      end
      expect(totals).to eq([0, 0, 0, 0, 0, 0])
    end
  end

  context 'when a decision record has no Status section' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-602-statusless.md', <<~MD)
        ---
        title: "ADR-602: No Status Section"
        ---

        body without status
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Records with no Status table contribute to no velocity bar. >[SRS-075] </REQ>
    it 'leaves the chart datasets empty for a statusless record' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      totals = Array.new(data['labels'].length, 0)
      data['datasets'].each do |ds|
        ds['data'].each_with_index { |v, i| totals[i] += v }
      end
      expect(totals).to eq([0, 0, 0, 0, 0, 0])
    end
  end

  context 'when decision records use mixed status vocabularies' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-603-impl.md', <<~MD)
        ---
        title: "ADR-603: Standard Workflow"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2024 | Implemented |
      MD
      write_file('myproject/decisions/issue-604-done.md', <<~MD)
        ---
        title: "ISSUE-604: Issue Workflow"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2024 | Done |
      MD
      write_file('myproject/decisions/enh-605-pending.md', <<~MD)
        ---
        title: "ENH-605: Enhancement Workflow"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2024 | Pending Review |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Status segments = union of every distinct status text. >[SRS-076] </REQ>
    it 'creates a separate dataset for each distinct status text' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      labels = data['datasets'].map { |d| d['label'] }
      expect(labels).to include('Implemented', 'Done', 'Pending Review')
      data['datasets'].each do |ds|
        next unless %w[Implemented Done].include?(ds['label']) || ds['label'] == 'Pending Review'

        expect(ds['data']).to eq([1, 1, 1, 1, 1, 1])
      end
    end
  end

  context 'when a Status table has multiple rows on the same date' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-606-same-date.md', <<~MD)
        ---
        title: "ADR-606: Same-Date Rows"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 01-01-2024 | Proposed |
        |   | 01-01-2024 | Accepted |
        | * | 01-01-2024 | In-Progress |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Same-date tie broken by document order; later row wins. >[SRS-073] </REQ>
    it 'picks the row that appears later in document order' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      in_progress = data['datasets'].find { |d| d['label'] == 'In-Progress' }
      expect(in_progress).not_to be_nil
      expect(in_progress['data']).to eq([1, 1, 1, 1, 1, 1])
      proposed = data['datasets'].find { |d| d['label'] == 'Proposed' }
      expect(proposed&.dig('data')).to be_nil.or(eq([0, 0, 0, 0, 0, 0]))
    end
  end

  context 'when a Status table has rows whose dates straddle the chart window' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-607-mixed.md', <<~MD)
        ---
        title: "ADR-607: Mixed Past/Future Rows"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        |   | 01-01-2024 | Proposed |
        | * | 02-01-2024 | Implemented |
        |   | 01-01-2030 | Archived |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Future-dated rows are ignored for past Fridays. >[SRS-073] </REQ>
    it 'ignores future-dated rows on Fridays earlier than their date' do
      data = velocity_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      implemented = data['datasets'].find { |d| d['label'] == 'Implemented' }
      expect(implemented).not_to be_nil
      expect(implemented['data']).to eq([1, 1, 1, 1, 1, 1])
      archived = data['datasets'].find { |d| d['label'] == 'Archived' }
      expect(archived&.dig('data')).to be_nil.or(eq([0, 0, 0, 0, 0, 0]))
    end
  end

  def status_data_block(html)
    block = html[/decisions_status_bar.*?data:\s*(\{.*?\}),\s*options:/m, 1]
    JSON.parse(block)
  end

  # Count for the category whose label starts with the given status text.
  def status_count(data, status)
    idx = data['labels'].index { |l| l.start_with?("#{status} (") }
    idx && data['datasets'][0]['data'][idx]
  end

  def write_status_record(id, title, status_rows)
    rows = status_rows.map { |marker, date, status| "| #{marker} | #{date} | #{status} |" }.join("\n")
    write_file("myproject/decisions/#{id}.md", <<~MD)
      ---
      title: "#{title}"
      ---

      # Status

      |  | Date | Status |
      |:---:|---|---|
      #{rows}
    MD
  end

  context 'when decision records have current statuses' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_status_record('adr-700-impl-a', 'ADR-700', [['*', '01-01-2025', 'Implemented']])
      write_status_record('adr-701-impl-b', 'ADR-701', [['*', '01-01-2025', 'Implemented']])
      write_status_record('adr-702-prop', 'ADR-702', [['*', '01-01-2025', 'Proposed']])
      write_status_record('adr-703-lower', 'ADR-703', [['*', '01-01-2025', 'proposed']])
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A horizontal bar chart of records by current status sits in the third chart cell. >[SRS-083] </REQ>
    it 'emits a horizontal bar chart after the velocity chart' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(html).to include('id="decisions_status_bar"')
      expect(html).to match(/decisions_status_bar.*?type:\s*'bar'/m)
      expect(html).to match(/decisions_status_bar.*?indexAxis:\s*'y'/m)
      expect(html.index('decisions_status_bar')).to be > html.index('decisions_velocity_bar')
    end

    # <REQ> Records counted under their *-marked current status, matched case-sensitively. >[SRS-084] </REQ>
    it 'counts records under their current status and keeps case-distinct statuses separate' do
      data = status_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      expect(status_count(data, 'Implemented')).to eq(2)
      expect(status_count(data, 'Proposed')).to eq(1)
      expect(status_count(data, 'proposed')).to eq(1)
    end

    # <REQ> Linear scale with the count shown in each bar label. >[SRS-086] </REQ>
    it 'uses a linear scale and shows the count in every label' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(html).to match(/decisions_status_bar.*?beginAtZero:\s*true/m)
      expect(html).not_to match(/decisions_status_bar.*?type:\s*'logarithmic'/m)
      data = status_data_block(html)
      data['labels'].each { |l| expect(l).to match(/\(\d+\)\z/) }
    end

    # <REQ> No "Undefined" category when every record has a defined current status. >[SRS-085] </REQ>
    it 'omits the Undefined category when all records have a defined status' do
      data = status_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      expect(data['labels']).to all(satisfy { |l| !l.start_with?('Undefined (') })
    end
  end

  context 'when decision records have missing or ambiguous current-status markers' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_status_record('adr-710-defined', 'ADR-710', [['*', '01-01-2025', 'Implemented']])
      # no marker at all -> current status undefined
      write_status_record('adr-711-no-marker', 'ADR-711', [[' ', '01-01-2025', 'Proposed']])
      # two markers -> current status ambiguous, also undefined
      write_status_record('adr-712-two-markers', 'ADR-712',
                          [['*', '01-01-2025', 'Proposed'], ['*', '02-01-2025', 'Accepted']])
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Records with a missing or ambiguous marker are grouped under "Undefined". >[SRS-085] </REQ>
    it 'groups both the markerless and the multi-marker record under Undefined' do
      data = status_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      expect(status_count(data, 'Undefined')).to eq(2)
      expect(status_count(data, 'Implemented')).to eq(1)
    end

    # <REQ> The "Undefined" category is ordered last, after all real statuses. >[SRS-087] </REQ>
    it 'places the Undefined category last' do
      data = status_data_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      undefined_idx = data['labels'].index { |l| l.start_with?('Undefined (') }
      expect(undefined_idx).to eq(data['labels'].length - 1)
    end
  end

  # --- Owner column (ADR-193, retained by ADR-222) ------------------------------
  #
  # The overview's Owner column is populated with each record's distinct,
  # first-seen-ordered Scope owners.

  # The Owner cell (last item_meta cell) of the overview row for a decision id.
  def owner_cell(id)
    doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
    row = doc.at_xpath(%(//a[@id="#{id}"]/ancestor::tr))
    row.css('td.item_meta').last.text.strip
  end

  context 'when decision records have Scope owners' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-800-owned.md', <<~MD)
        ---
        title: "ADR-800: Owned Work"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | In-Progress | analysis work |
        | 2 | Code | DEV | To Do | code work |
        | 3 | Tests | TEST | To Do | test work |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # The type pie is back in the first chart cell and the WIP chart is gone (ADR-222).
    it 'emits the type pie chart in the first cell and no WIP chart' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(html).to include('id="decisions_type_pie"')
      expect(html).to include('Decision Records by Type')
      expect(html).not_to include('decisions_wip_bar')
      expect(html.index('decisions_type_pie')).to be < html.index('decisions_velocity_bar')
    end

    # The overview renders no work-item Gantt and no Kit column (ADR-222).
    it 'renders neither a Gantt nor a Kit column' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(html).not_to include('workitem_gantt')
      expect(html).not_to include('<th title="Cross-record full-kit readiness">Kit</th>')
      doc = Nokogiri::HTML(html)
      expect(doc.at_css('#critical_chain_menu_item')).to be_nil
    end

    # <REQ> The distinct owners are rendered in the overview Owner column. >[SRS-110] </REQ>
    it 'lists the record distinct owners in the Owner column' do
      expect(owner_cell('adr-800')).to eq('BA, DEV, TEST')
    end
  end

  context 'when the Scope table has Owner and Status in a non-default order' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-802-reordered.md', <<~MD)
        ---
        title: "ADR-802: Reordered"
        ---

        # Scope

        | Status | Description | Item | Owner |
        |---|---|---|---|
        | In-Progress | work | Analysis | BA |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Owner is located by header text, not column position. >[SRS-108] </REQ>
    it 'reads Owner by header text regardless of position' do
      expect(owner_cell('adr-802')).to eq('BA')
    end
  end

  context 'when a Scope table repeats and interleaves owners' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-803-repeat.md', <<~MD)
        ---
        title: "ADR-803: Repeated Owners"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | Done | a |
        | 2 | Requirements | DEV | Done | b |
        | 3 | Code | BA | To Do | c |
        | 4 | Tests | TEST | To Do | d |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The Owner cell shows each owner once, in first-seen order. >[SRS-108] >[SRS-110] </REQ>
    it 'shows the distinct owners once in first-seen order' do
      expect(owner_cell('adr-803')).to eq('BA, DEV, TEST')
    end
  end

  context 'when a decision record has no Owner column' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-804-noowner.md', <<~MD)
        ---
        title: "ADR-804: No Owner Column"
        ---

        # Scope

        | # | Item | Status | Description |
        |---|---|---|---|
        | 1 | Analysis | In-Progress | work |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> No Owner column yields an empty owner list and an empty overview cell. >[SRS-109] </REQ>
    it 'leaves the Owner cell empty' do
      expect(owner_cell('adr-804')).to eq('')
    end
  end

  context 'when a decision record has a blank Owner cell' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-805-blankowner.md', <<~MD)
        ---
        title: "ADR-805: Blank Owner"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis |  | In-Progress | work |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A blank Owner cell contributes no owner. >[SRS-109] </REQ>
    it 'treats a blank Owner cell as no owner' do
      expect(owner_cell('adr-805')).to eq('')
    end
  end

  context 'when a decision record has no Scope table' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-806-noscope.md', <<~MD)
        ---
        title: "ADR-806: No Scope"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2025 | Accepted |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A record with no Scope table has an empty owner list. >[SRS-109] </REQ>
    it 'leaves the Owner cell empty' do
      expect(owner_cell('adr-806')).to eq('')
    end
  end

  # --- Scope table rendering (ADR-210, slimmed by ADR-222) ----------------------

  # The Depends On cell nodes of the Scope row whose Item cell equals `item`.
  def scope_row_cells(page, item)
    doc = Nokogiri::HTML(File.read(expand_path(page)))
    row = doc.css('table.markdown_table tr').find do |tr|
      tr.css('td').any? { |c| c.text.strip == item }
    end
    row || Nokogiri::XML.fragment('')
  end

  context 'when a Scope table carries step numbers, dependencies, and dates' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-900-dependent.md', <<~MD)
        ---
        title: "ADR-900: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status | Start Date | Target Date | Description |
        |---|---|---|---|---|---|---|---|
        | 1 | Requirements | BA |  | Done | 01-06-2026 | 02-06-2026 | reqs |
        | 2 | Code | DEV | >[ADR-901], >[ADR-999] | To Do |  |  | code |
      MD
      write_file('myproject/decisions/adr-901-prerequisite.md', <<~MD)
        ---
        title: "ADR-901: Prerequisite"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Code | DEV | Done | code |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The step-number column renders as an anchored row number. >[SRS-113] </REQ>
    it 'anchors each Scope row on its namespaced step number' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/adr-900.html')))
      anchor = doc.at_css('table.markdown_table a[id="adr-900.scope.1"]')
      expect(anchor).not_to be_nil
      expect(anchor['name']).to eq('adr-900.scope.1')
      expect(anchor.text.strip).to eq('1')
    end

    # <REQ> A Depends On reference renders as a clickable link to the referenced record. >[SRS-115] </REQ>
    it 'links a resolved Depends On reference to the record page' do
      link = scope_row_cells('myproject/build/decisions/adr-900.html', 'code').css('a.external').first
      expect(link).not_to be_nil
      expect(link.text.strip).to eq('ADR-901')
      expect(link['href']).to end_with('adr-901.html')
    end

    # <REQ> An unresolved Depends On reference renders in the broken-link style. >[SRS-115] </REQ>
    it 'renders an unresolved Depends On reference as a broken-link span' do
      spans = scope_row_cells('myproject/build/decisions/adr-900.html', 'code').css('span.broken_link')
      expect(spans.map { |s| s.text.strip }).to eq(%w[ADR-999])
    end

    # The Start/Target Date cells keep the ENH-214 nowrap class.
    it 'tags the Start and Target Date cells with the scope_date class' do
      cells = scope_row_cells('myproject/build/decisions/adr-900.html', 'reqs').css('td.scope_date')
      expect(cells.map { |c| c.text.strip }).to eq(%w[01-06-2026 02-06-2026])
    end
  end
end
