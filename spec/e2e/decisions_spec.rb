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
      expect(header_cells).to eq(['#', 'Type', 'Status', 'Title', 'Start Date', 'Target Date', 'Release', 'Owner',
                                  'Kit'])
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

  # --- Owner column & Work-In-Progress by Owner chart (ADR-193) ----------------
  #
  # The overview gains an Owner column populated from the Scope table, and the
  # left chart cell becomes a Work-In-Progress by Owner bar chart (with a dashed
  # reference line at the configured wip_limit) in place of the type pie. The WIP
  # chart's data block is hand-written JS rather than to_json, so its arrays are
  # extracted individually instead of being parsed as a whole.

  def wip_block(html)
    html[/decisions_wip_bar.*?\}\);/m, 0]
  end

  def wip_labels(html)
    JSON.parse(wip_block(html)[/labels:\s*(\[[^\]]*\])/, 1])
  end

  def wip_bars(html)
    JSON.parse(wip_block(html)[/In-progress items', data:\s*(\[[^\]]*\])/, 1])
  end

  def wip_colors(html)
    JSON.parse(wip_block(html)[/backgroundColor:\s*(\[[^\]]*\])/, 1])
  end

  def wip_limit_line(html)
    JSON.parse(wip_block(html)[/WIP limit', data:\s*(\[[^\]]*\])/, 1])
  end

  # The bar height for a given owner, or nil when that owner has no bar.
  def wip_count(html, owner)
    idx = wip_labels(html).index(owner)
    idx && wip_bars(html)[idx]
  end

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

    # <REQ> The WIP-by-Owner chart replaces the type pie in the first chart cell. >[SRS-111] </REQ>
    it 'emits a Work In Progress by Owner chart and no longer emits the type pie' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(html).to include('id="decisions_wip_bar"')
      expect(html).to include('Work In Progress by Owner')
      expect(html).not_to include('decisions_type_pie')
      expect(html.index('decisions_wip_bar')).to be < html.index('decisions_velocity_bar')
    end

    # <REQ> The freeze limit renders as a dashed line dataset using core Chart.js. >[SRS-111] </REQ>
    it 'draws the wip_limit as a dashed line dataset' do
      block = wip_block(File.read(expand_path('myproject/build/decisions/overview.html')))
      expect(block).to match(/type:\s*'line'/)
      expect(block).to match(/borderDash/)
    end

    # <REQ> The distinct owners are rendered in the overview Owner column. >[SRS-110] </REQ>
    it 'lists the record distinct owners in the Owner column' do
      expect(owner_cell('adr-800')).to eq('BA, DEV, TEST')
    end
  end

  context 'when a record is in its Analysis phase' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-801-analysis.md', <<~MD)
        ---
        title: "ADR-801: In Analysis"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | In-Progress | analysis |
        | 2 | Requirements | BA | Done | done reqs |
        | 3 | Code | DEV | To Do | code |
        | 4 | Tests | TEST | To Do | tests |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Every owner is shown; the in-progress row counts, idle roles render at zero. >[SRS-111] </REQ>
    it 'shows every owner, counting the analyst over zero and idle roles at zero' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(wip_labels(html)).to eq(%w[BA DEV TEST])
      expect(wip_count(html, 'BA')).to eq(1)
      expect(wip_count(html, 'DEV')).to eq(0)
      expect(wip_count(html, 'TEST')).to eq(0)
    end

    # <REQ> A Done Scope row contributes no work in progress. >[SRS-111] </REQ>
    it 'does not count a Done row toward its owner' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      # BA owns both the In-Progress Analysis and the Done Requirements; only the former counts.
      expect(wip_count(html, 'BA')).to eq(1)
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

    # <REQ> Owner and Status are located by header text, not column position. >[SRS-108] </REQ>
    it 'reads Owner and Status by header text regardless of position' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(owner_cell('adr-802')).to eq('BA')
      expect(wip_count(html, 'BA')).to eq(1)
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
    it 'leaves the Owner cell empty and adds nothing to the WIP chart' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(owner_cell('adr-804')).to eq('')
      expect(wip_labels(html)).to be_empty
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
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(owner_cell('adr-805')).to eq('')
      expect(wip_labels(html)).to be_empty
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

  context 'when project.yml sets a custom planning wip_limit' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        planning:
          wip_limit: 3
      YML
      write_file('myproject/decisions/adr-807-overloaded.md', <<~MD)
        ---
        title: "ADR-807: Overloaded BA"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | In-Progress | a |
        | 2 | Requirements | BA | In-Progress | b |
        | 3 | Design | BA | In-Progress | c |
        | 4 | Review | BA | In-Progress | d |
        | 5 | Code | DEV | In-Progress | e |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The reference line reflects the configured wip_limit. >[SRS-111] >[SRS-112] </REQ>
    it 'draws the reference line at the configured limit' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(wip_limit_line(html).uniq).to eq([3])
    end

    # <REQ> An owner above the limit is drawn in the warning colour. >[SRS-111] </REQ>
    it 'colours the over-limit owner with the warning colour' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      colors = wip_colors(html)
      ba_idx = wip_labels(html).index('BA')
      dev_idx = wip_labels(html).index('DEV')
      expect(colors[ba_idx]).to include('255, 99, 132')      # BA = 4 > 3 -> warning
      expect(colors[dev_idx]).not_to include('255, 99, 132') # DEV = 1 <= 3 -> normal
    end
  end

  context 'when planning wip_limit is absent' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-808-default.md', <<~MD)
        ---
        title: "ADR-808: Default Limit"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | In-Progress | a |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> An absent wip_limit falls back to a default of 2. >[SRS-112] </REQ>
    it 'defaults the reference line to 2' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(wip_limit_line(html).uniq).to eq([2])
    end
  end

  context 'when planning wip_limit is invalid' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        planning:
          wip_limit: 0
      YML
      write_file('myproject/decisions/adr-809-invalid.md', <<~MD)
        ---
        title: "ADR-809: Invalid Limit"
        ---

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | In-Progress | a |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A non-positive or non-integer wip_limit falls back to the default of 2. >[SRS-112] </REQ>
    it 'falls back to the default of 2 for a non-positive value' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(wip_limit_line(html).uniq).to eq([2])
    end
  end

  context 'when the record lifecycle status differs from its Scope row statuses' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      # Lifecycle says Implemented, but a Scope row is still In-Progress.
      write_file('myproject/decisions/adr-810-mismatch.md', <<~MD)
        ---
        title: "ADR-810: Status Mismatch"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2025 | Implemented |

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Analysis | BA | In-Progress | still going |
      MD
      # Lifecycle says In-Progress, but every Scope row is To Do.
      write_file('myproject/decisions/adr-811-quiet.md', <<~MD)
        ---
        title: "ADR-811: Quiet"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-01-2025 | In-Progress |

        # Scope

        | # | Item | Owner | Status | Description |
        |---|---|---|---|---|
        | 1 | Code | DEV | To Do | not started |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> WIP reads the per-row Status, independent of the record lifecycle status. >[SRS-107] >[SRS-111] </REQ>
    it 'counts an in-progress Scope row even when the lifecycle status is Implemented' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(wip_count(html, 'BA')).to eq(1)
    end

    # <REQ> A To Do Scope row adds no WIP even when the lifecycle status is In-Progress. >[SRS-107] >[SRS-111] </REQ>
    it 'shows an idle owner at zero even when its lifecycle status is In-Progress' do
      html = File.read(expand_path('myproject/build/decisions/overview.html'))
      expect(wip_count(html, 'DEV')).to eq(0)
    end
  end

  # ----- ADR-194: phase ordering, dependency readiness, full kit -----

  # The overview Kit cell node for a decision id (nil when the row is absent).
  def kit_node(id)
    doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
    row = doc.at_xpath(%(//a[@id="#{id}"]/ancestor::tr))
    row&.at_css('td.item_kit')
  end

  def kit_cell(id)
    kit_node(id)&.text&.strip
  end

  # The Depends On links (hrefs) of the Scope row whose Item cell equals `item`,
  # on the given decision page.
  def scope_row_links(page, item)
    scope_row_cells(page, item).css('a.external').map { |a| a['href'] }
  end

  # The unresolved (broken-link span) texts of that same Scope row.
  def scope_row_unresolved(page, item)
    scope_row_cells(page, item).css('span.broken_link').map { |s| s.text.strip }
  end

  def scope_row_cells(page, item)
    doc = Nokogiri::HTML(File.read(expand_path(page)))
    row = doc.css('table.markdown_table tr').find do |tr|
      tr.css('td').any? { |c| c.text.strip == item }
    end
    row || Nokogiri::XML.fragment('')
  end

  context 'when a started Scope row has an unfinished lower-numbered step' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-410-phase.md', <<~MD)
        ---
        title: "ADR-410: Phase order"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Requirements | BA | To Do |
        | 2 | Code | DEV | In-Progress |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A started row with an unfinished lower step is reported; build still completes. >[SRS-114] </REQ>
    it 'reports the phase-order violation naming the row and the blocking step' do
      expect(last_command_started.stdout)
        .to match(/phase order: adr-410\.2\.Code started before adr-410\.1\.Requirements/)
    end

    # <REQ> Phase-order violations are non-failing advisories; the build completes. >[SRS-114] </REQ>
    it 'still renders the overview' do
      expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be true
    end

    # <REQ> The Kit column is cross-record only; it is empty when the record declares no Depends On. >[SRS-119] </REQ>
    it 'leaves the Kit cell empty (a phase-order issue is intra-record, not a Depends On)' do
      expect(kit_cell('adr-410')).to eq('')
    end
  end

  context 'when Scope rows share a step number or omit the # column' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      # adr-420: two rows share step 1 (concurrent), one started one not -> no violation
      write_file('myproject/decisions/adr-420-concurrent.md', <<~MD)
        ---
        title: "ADR-420: Concurrent"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | In-Progress |
        | 1 | Requirements | BA | To Do |
      MD
      # adr-421: no # column -> intrinsic row order; row 2 started before row 1 done -> violation
      write_file('myproject/decisions/adr-421-roworder.md', <<~MD)
        ---
        title: "ADR-421: Row order"
        ---

        # Scope

        | Item | Owner | Status |
        |---|---|---|
        | Requirements | BA | To Do |
        | Code | DEV | In-Progress |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Rows sharing a step number are concurrent, not blocked by each other. >[SRS-113] </REQ>
    it 'does not flag equal-numbered rows as a phase-order violation' do
      expect(last_command_started.stdout).not_to match(/phase order: adr-420/)
    end

    # <REQ> With no # column the intrinsic row order applies. >[SRS-113] >[SRS-114] </REQ>
    it 'uses row order when the # column is absent' do
      expect(last_command_started.stdout)
        .to match(/phase order: adr-421\.2\.Code started before adr-421\.1\.Requirements/)
    end
  end

  context 'when one record Depends On another in the same group' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/release x/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | Done |
        | 2 | Code | DEV | In-Progress |
      MD
      write_file('myproject/decisions/release x/adr-2-dep.md', <<~MD)
        ---
        title: "ADR-2: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Analysis | BA | >[ADR-1] | To Do |
        | 2 | Code | DEV | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A Depends On reference resolves to the target's work item of the same activity type. >[SRS-115] </REQ>
    it 'aligns each Depends On row to the prerequisite row of the same activity type' do
      page = 'myproject/build/decisions/release x/adr-2.html'
      expect(scope_row_links(page, 'Analysis')).to eq(['adr-1.html#adr-1.scope.1'])
      expect(scope_row_links(page, 'Code')).to eq(['adr-1.html#adr-1.scope.2'])
    end

    # <REQ> A dependent's Analysis is met by the prerequisite's Analysis, not its Code. >[SRS-115] >[SRS-116] </REQ>
    it 'derives readiness from the activity-aligned predecessor, not the whole record' do
      # ADR-1.Analysis is Done but ADR-1.Code is In-Progress: ADR-2 is blocked overall
      # because ADR-2.Code depends on the not-yet-Done ADR-1.Code.
      expect(kit_cell('adr-2')).to eq('Blocked')
    end

    # <REQ> The Owner does not affect Depends On resolution. >[SRS-115] </REQ>
    it 'is unaffected by the differing owners on the two records' do
      expect(scope_row_links('myproject/build/decisions/release x/adr-2.html', 'Analysis'))
        .to eq(['adr-1.html#adr-1.scope.1'])
    end
  end

  context 'when a prerequisite work item is Done' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/g/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | Done |
      MD
      write_file('myproject/decisions/g/adr-2-ready.md', <<~MD)
        ---
        title: "ADR-2: Ready"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Analysis | BA | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A row is kitted when its resolved predecessor's Status is Done. >[SRS-116] >[SRS-119] </REQ>
    it 'renders Ready and reports no kit violation' do
      expect(kit_cell('adr-2')).to eq('Ready')
      expect(last_command_started.stdout).not_to match(/kit violations/)
    end
  end

  context 'when a started row is blocked by an unsatisfied cross-record predecessor' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/g/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Code | DEV | In-Progress |
      MD
      write_file('myproject/decisions/g/adr-2-started.md', <<~MD)
        ---
        title: "ADR-2: Started"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-1] | In-Progress |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A started row with a not-Done resolved predecessor is a cross-record violation. >[SRS-117] </REQ>
    it 'reports the cross-record kit violation naming the row and the predecessor' do
      expect(last_command_started.stdout).to match(/not kitted: adr-2\.1\.Code needs adr-1\.1\.Code/)
    end

    # <REQ> The overview emphasises a record blocked while having a started row. >[SRS-117] >[SRS-119] </REQ>
    it 'renders Blocked and emphasises the cell' do
      node = kit_node('adr-2')
      expect(node.text.strip).to eq('Blocked')
      expect(node['style']).to include('font-weight: bold')
    end
  end

  context 'when the dependent activity is absent from the prerequisite' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      # ADR-1 has Analysis + Code but no Tests row.
      write_file('myproject/decisions/g/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | Done |
        | 2 | Code | DEV | Done |
      MD
      write_file('myproject/decisions/g/adr-2-tests.md', <<~MD)
        ---
        title: "ADR-2: Tests"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Tests | TEST | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Resolution falls back to the nearest earlier activity when no exact match exists. >[SRS-115] </REQ>
    it 'falls back to the nearest earlier activity (Code) for a Tests row' do
      expect(scope_row_links('myproject/build/decisions/g/adr-2.html', 'Tests'))
        .to eq(['adr-1.html#adr-1.scope.2'])
    end
  end

  context 'when a Depends On crosses into another planning group' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/release a/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Code | DEV | In-Progress |
      MD
      write_file('myproject/decisions/release b/adr-3-cross.md', <<~MD)
        ---
        title: "ADR-3: Cross group"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A cross-group Depends On blocks readiness until the predecessor is Done. >[SRS-116] >[SRS-117] </REQ>
    it 'blocks the dependent on its cross-group predecessor' do
      expect(kit_cell('adr-3')).to eq('Blocked')
    end

    # <REQ> A real record in another group is honoured, never warned as unresolved. >[SRS-118] </REQ>
    it 'does not warn about the cross-group reference' do
      expect(last_command_started.stdout).not_to match(/unresolved Depends On/)
    end

    # <REQ> The cross-group link resolves across the folder boundary to the aligned row. >[SRS-115] </REQ>
    it 'deep-links across the group folders to the aligned row' do
      expect(scope_row_links('myproject/build/decisions/release b/adr-3.html', 'Code'))
        .to eq(['../release%20a/adr-1.html#adr-1.scope.1'])
    end
  end

  context 'when a Depends On reference does not resolve' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-5-bad.md', <<~MD)
        ---
        title: "ADR-5: Bad ref"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-999] | In-Progress |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> An unresolved Depends On reference is reported without failing the build. >[SRS-118] </REQ>
    it 'reports the unresolved reference and still renders' do
      expect(last_command_started.stdout).to match(/unresolved Depends On: adr-5 -> ADR-999/)
      expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be true
    end

    # <REQ> An unresolved reference renders as a broken-link span in the Scope table. >[SRS-118] </REQ>
    it 'renders the unresolved reference as a broken link' do
      expect(scope_row_unresolved('myproject/build/decisions/adr-5.html', 'Code')).to eq(['ADR-999'])
    end
  end

  context 'when records differ in their declared prerequisites and readiness' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      # adr-1: no Depends On -> empty Kit
      write_file('myproject/decisions/g/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | Done |
      MD
      # adr-2: depends on adr-1 (Done) -> Ready
      write_file('myproject/decisions/g/adr-2-ready.md', <<~MD)
        ---
        title: "ADR-2: Ready"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Analysis | BA | >[ADR-1] | To Do |
      MD
      # adr-3: depends on adr-2 (To Do, not Done) -> Blocked
      write_file('myproject/decisions/g/adr-3-blocked.md', <<~MD)
        ---
        title: "ADR-3: Blocked"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Analysis | BA | >[ADR-2] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The Kit column is empty, Ready, or Blocked per the record's prerequisites. >[SRS-119] </REQ>
    it 'renders empty / Ready / Blocked across the three records' do
      expect(kit_cell('adr-1')).to eq('')
      expect(kit_cell('adr-2')).to eq('Ready')
      expect(kit_cell('adr-3')).to eq('Blocked')
    end
  end

  context 'when the record lifecycle status diverges from its Scope row statuses' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/g/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 01-06-2026 | Implemented |

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Code | DEV | To Do |
      MD
      write_file('myproject/decisions/g/adr-2-dep.md', <<~MD)
        ---
        title: "ADR-2: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Readiness reads the bounded per-row Status, never the record lifecycle status. >[SRS-116] </REQ>
    it 'treats an Implemented record with a To Do Scope row as not Done' do
      expect(kit_cell('adr-2')).to eq('Blocked')
    end
  end

  context 'when a record has both a Scope and an Affected Documents table' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/specifications/req/req.md', "# Requirements\n\n[REQ-001] A requirement.\n")
      write_file('myproject/decisions/g/adr-1-both.md', <<~MD)
        ---
        title: "ADR-1: Both tables"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | Done |
        | 2 | Code | DEV | Done |

        # Affected Documents

        | # | Proposed Text | Req-ID |
        |---|---|---|
        | 1 | First. | >[REQ-001] |
        | 2 | Second. | >[REQ-001] |
      MD
      write_file('myproject/decisions/g/adr-2-dep.md', <<~MD)
        ---
        title: "ADR-2: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Scope row anchors are namespaced so they do not collide with Affected Documents. >[SRS-113] </REQ>
    it 'emits distinct, non-colliding anchors for the two tables' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/g/adr-1.html')))
      ids = doc.xpath('//*[starts-with(@id, "adr-1.")]/@id').map(&:value)
      expect(ids).to contain_exactly('adr-1.1', 'adr-1.2', 'adr-1.scope.1', 'adr-1.scope.2')
    end

    # <REQ> A Depends On link targets the namespaced Scope anchor of the aligned row. >[SRS-115] </REQ>
    it 'links a dependent to the namespaced Scope anchor' do
      expect(scope_row_links('myproject/build/decisions/g/adr-2.html', 'Code'))
        .to eq(['adr-1.html#adr-1.scope.2'])
    end
  end

  context 'when a Depends On target has no # step column' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/g/adr-1-nostep.md', <<~MD)
        ---
        title: "ADR-1: No step column"
        ---

        # Scope

        | Item | Owner | Status |
        |---|---|---|
        | Code | DEV | Done |
      MD
      write_file('myproject/decisions/g/adr-2-dep.md', <<~MD)
        ---
        title: "ADR-2: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> With no step column on the target there is no anchor, so the link opens the record. >[SRS-115] </REQ>
    it 'links to the record page without a fragment' do
      expect(scope_row_links('myproject/build/decisions/g/adr-2.html', 'Code')).to eq(['adr-1.html'])
    end
  end

  # ----- ADR-198: work-item swimlane Gantt on the overview -----

  def overview_doc
    Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
  end

  def gantt_container(doc = overview_doc)
    doc.at_css('div.workitem_gantt')
  end

  # The owner-lane labels, top to bottom.
  def gantt_lanes(doc = overview_doc)
    doc.css('div.workitem_gantt .gantt_owner').map { |o| o.text.strip }
  end

  # Geometry of the bar whose label is "<record> <activity>": its grid-column
  # start, day span, grid-row, and CSS class list. nil when no such bar.
  def gantt_bar(label, doc = overview_doc)
    node = doc.css('div.workitem_gantt .gantt_bar').find { |b| b.text.strip == label }
    return nil unless node

    col = node['style'].match(%r{grid-column:\s*(\d+)\s*/\s*span\s*(\d+)})
    row = node['style'].match(/grid-row:\s*(\d+)/)
    { start: col[1].to_i, span: col[2].to_i, row: row[1].to_i, classes: node['class'].split }
  end

  context 'when the overview renders the work-item Gantt' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | Done |
        | 2 | Code | DEV | Done |
      MD
      write_file('myproject/decisions/adr-2-dep.md', <<~MD)
        ---
        title: "ADR-2: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Analysis | BA | >[ADR-1] | In-Progress |
        | 2 | Code | DEV | >[ADR-1] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The overview renders a work-item schedule between the charts and the records table. >[SRS-136] </REQ>
    it 'places the Gantt container between the charts grid and the records table' do
      doc = overview_doc
      nodes = doc.css('div.decisions_overview_charts, div.workitem_gantt, table.decisions_overview')
      expect(nodes.map { |n| n.name == 'table' ? 'table' : n['class'].split.first })
        .to eq(%w[decisions_overview_charts workitem_gantt table])
    end

    # <REQ> One lane per owner named across all records, in the shared roster order. >[SRS-136] </REQ>
    it 'draws one lane per owner across all records' do
      expect(gantt_lanes).to eq(%w[BA DEV])
    end

    # <REQ> Each work item is a bar of constant three-day duration. >[SRS-137] </REQ>
    it 'spans every bar three day-columns' do
      %w[Analysis Code].each do |item|
        expect(gantt_bar("ADR-1 #{item}")[:span]).to eq(3)
        expect(gantt_bar("ADR-2 #{item}")[:span]).to eq(3)
      end
    end

    # <REQ> A bar starts no earlier than the latest finish of its predecessors (intra-record step). >[SRS-138] </REQ>
    it 'starts a later step after its earlier same-record step finishes' do
      analysis = gantt_bar('ADR-1 Analysis')
      code = gantt_bar('ADR-1 Code')
      expect(code[:start]).to be >= (analysis[:start] + analysis[:span])
    end

    # <REQ> A bar starts no earlier than the latest finish of its cross-record predecessor. >[SRS-138] </REQ>
    it 'starts the dependent record after its activity-aligned predecessor finishes' do
      base = gantt_bar('ADR-1 Analysis')
      dependent = gantt_bar('ADR-2 Analysis')
      expect(dependent[:start]).to be >= (base[:start] + base[:span])
    end

    # <REQ> Work items sharing an owner do not overlap; the lane is serialised. >[SRS-139] </REQ>
    it 'serialises the two BA work items so their day spans do not overlap' do
      first = gantt_bar('ADR-1 Analysis')
      second = gantt_bar('ADR-2 Analysis')
      expect(first[:row]).to eq(second[:row])
      expect(second[:start]).to be >= (first[:start] + first[:span])
    end

    # <REQ> Each bar indicates its row Status. >[SRS-140] </REQ>
    it 'colours each bar by its row Status' do
      expect(gantt_bar('ADR-1 Analysis')[:classes]).to include('gantt_done')
      expect(gantt_bar('ADR-2 Analysis')[:classes]).to include('gantt_inprogress')
      expect(gantt_bar('ADR-2 Code')[:classes]).to include('gantt_todo')
    end

    # <REQ> The schedule is deterministic across runs. >[SRS-139] </REQ>
    it 'produces an identical Gantt on a second run' do
      first = gantt_container.to_html
      run_command_and_stop('almirah please myproject')
      expect(gantt_container.to_html).to eq(first)
    end
  end

  context 'when unlinked work items have different owners' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-30-parallel.md', <<~MD)
        ---
        title: "ADR-30: Parallel"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | To Do |
        | 1 | Code | DEV | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Different-owner work items with no dependency share day columns (run in parallel). >[SRS-139] </REQ>
    it 'starts both bars on the same day column' do
      expect(gantt_bar('ADR-30 Analysis')[:start]).to eq(gantt_bar('ADR-30 Code')[:start])
    end
  end

  context 'when a started work item is blocked by an unfinished cross-record predecessor' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/grp/adr-1-base.md', <<~MD)
        ---
        title: "ADR-1: Base"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Code | DEV | To Do |
      MD
      write_file('myproject/decisions/grp/adr-2-dep.md', <<~MD)
        ---
        title: "ADR-2: Dependent"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Code | DEV | >[ADR-1] | In-Progress |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A started-but-blocked work item is visually emphasised. >[SRS-140] </REQ>
    it 'marks the blocked bar with the violation emphasis' do
      expect(gantt_bar('ADR-2 Code')[:classes]).to include('gantt_blocked')
    end
  end

  context 'when no decision record declares Scope owners' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-40-plain.md', <<~MD)
        ---
        title: "ADR-40: Plain"
        ---

        ## Context

        A record with no Scope table.
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The Gantt container is omitted when there is nothing to schedule. >[SRS-136] </REQ>
    it 'omits the Gantt container' do
      expect(gantt_container).to be_nil
    end
  end

  # ----- ADR-201: group-segmented Gantt with a Buffer lane -----

  # The group band cells, left to right: each cell's label, grid-column start and span.
  def gantt_bands(doc = overview_doc)
    doc.css('div.workitem_gantt .gantt_release_band').map do |c|
      col = c['style'].match(%r{grid-column:\s*(\d+)\s*/\s*span\s*(\d+)})
      { name: c.text.strip, start: col[1].to_i, span: col[2].to_i }
    end
  end

  def buffer_bar_starts(doc = overview_doc)
    doc.css('div.workitem_gantt .gantt_buffer_bar').map { |b| b['style'][/grid-column:\s*(\d+)/, 1].to_i }
  end

  def grid_row(node)
    node['style'][/grid-row:\s*(\d+)/, 1].to_i
  end

  context 'when records span multiple decision groups' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/group-a/adr-10-a.md', <<~MD)
        ---
        title: "ADR-10: A"
        ---

        # Scope

        | # | Item | Owner | Status |
        |---|---|---|---|
        | 1 | Analysis | BA | To Do |
        | 2 | Code | DEV | To Do |
      MD
      write_file('myproject/decisions/group-b/adr-20-b.md', <<~MD)
        ---
        title: "ADR-20: B"
        ---

        # Scope

        | # | Item | Owner | Depends On | Status |
        |---|---|---|---|---|
        | 1 | Analysis | BA | >[ADR-10] | To Do |
        | 2 | Code | DEV | >[ADR-10] | To Do |
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The schedule is segmented into one block per group, in folder-encounter order. >[SRS-141] </REQ>
    it 'draws one group band per folder, left to right in encounter order' do
      bands = gantt_bands
      expect(bands.map { |b| b[:name] }).to eq(%w[group-a group-b])
      expect(bands[0][:start]).to be < bands[1][:start]
    end

    # <REQ> A group band spans its block's day columns, with a gutter between blocks. >[SRS-142] </REQ>
    it 'spans each band over its block and leaves a gutter before the next block' do
      bands = gantt_bands
      expect(bands[1][:start]).to be > (bands[0][:start] + bands[0][:span])
    end

    # <REQ> A predecessor in another group is treated as an already-available input. >[SRS-143] </REQ>
    it 'starts a cross-group dependent at its own block day one, not after its predecessor' do
      group_b_start = gantt_bands.find { |b| b[:name] == 'group-b' }[:start]
      expect(gantt_bar('ADR-20 Analysis')[:start]).to eq(group_b_start)
    end

    # <REQ> The same owner in different groups runs in parallel, not serialised across blocks. >[SRS-143] </REQ>
    it 'does not serialise the same owner across different group blocks' do
      bands = gantt_bands
      expect(gantt_bar('ADR-10 Analysis')[:start]).to eq(bands.find { |b| b[:name] == 'group-a' }[:start])
      expect(gantt_bar('ADR-20 Analysis')[:start]).to eq(bands.find { |b| b[:name] == 'group-b' }[:start])
    end

    # <REQ> The Buffer lane renders one buffer bar per group, after that group's last work item. >[SRS-144] </REQ>
    it 'renders a Buffer lane with one placeholder buffer bar per group after its work' do
      doc = overview_doc
      expect(doc.css('div.workitem_gantt .gantt_buffer').map { |n| n.text.strip }).to eq(['Buffer'])
      starts = buffer_bar_starts(doc)
      expect(starts.length).to eq(2)
      code_a = gantt_bar('ADR-10 Code', doc)
      expect(starts.min).to be >= (code_a[:start] + code_a[:span])
    end

    # <REQ> The Buffer lane is the last row, below every owner lane. >[SRS-144] </REQ>
    it 'places the Buffer lane below every owner lane' do
      doc = overview_doc
      buffer_row = grid_row(doc.at_css('div.workitem_gantt .gantt_buffer'))
      owner_rows = doc.css('div.workitem_gantt .gantt_owner').map { |o| grid_row(o) }
      expect(owner_rows).to all(be < buffer_row)
    end

    # <REQ> The segmented layout is identical across runs. >[SRS-145] </REQ>
    it 'produces an identical segmented Gantt on a second run' do
      first = gantt_container.to_html
      run_command_and_stop('almirah please myproject')
      expect(gantt_container.to_html).to eq(first)
    end
  end
end
