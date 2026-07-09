# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the Risks top-menu entry and the all-registries summary page
# introduced by ADR-219: the conditional button leads to build/risks/
# overview.html, one row per registry with Total, Open, and leading-group
# RPN aggregates, the Highest RPN cell keeping the threshold colouring.
RSpec.describe 'Risks Menu and Registries Page', type: :aruba do
  def summary_table(project_html_path)
    doc = Nokogiri::HTML(File.read(expand_path(project_html_path)))
    doc.at_css('table.risks_overview')
  end

  def registry_row_cells(table, name)
    row = table.at_css("a[id=\"#{name}\"]").ancestors('tr').first
    row.css('td')
  end

  def write_status_risk(registry, id, title, status)
    marker = status ? '*' : ' '
    write_file("myproject/risks/#{registry}/#{id}.md", <<~MD)
      ---
      title: "#{title}"
      ---

      # Status

      |  | Date | Status |
      |:---:|---|---|
      | #{marker} | 05-07-2026 | #{status || 'Identified'} |
    MD
  end

  context 'when the project has two registries, one with a leading RPN group' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: product
            columns: [Severity, Status]
            rpn:
              - name: Initial
                inputs: [Severity, Occurrence, Detection]
                thresholds:
                  acceptable: 20
                  unacceptable: 100
      YML
      write_file('myproject/specifications/req/req.md', <<~MD)
        # Requirements

        [REQ-001] A first requirement.
      MD
      # 48 (caution), Mitigating -> open
      write_file('myproject/risks/product/prodr-001-mid.md', <<~MD)
        ---
        title: "PRODR-001: Mid"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 05-07-2026 | Mitigating |

        # Severity

        8

        # Occurrence

        3

        # Detection

        2
      MD
      # 120 (unacceptable), Identified -> open
      write_file('myproject/risks/product/prodr-002-high.md', <<~MD)
        ---
        title: "PRODR-002: High"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 05-07-2026 | Identified |

        # Severity

        10

        # Occurrence

        6

        # Detection

        2
      MD
      # 18 (acceptable), Closed -> not open
      write_file('myproject/risks/product/prodr-003-closed.md', <<~MD)
        ---
        title: "PRODR-003: Closed"
        ---

        # Status

        |  | Date | Status |
        |:---:|---|---|
        | * | 05-07-2026 | Closed |

        # Severity

        2

        # Occurrence

        3

        # Detection

        3
      MD
      # blank RPN (no sections), no status marker -> still open
      write_status_risk('product', 'prodr-004-unmarked', 'PRODR-004: Unmarked', nil)
      # unconfigured registry
      write_status_risk('process', 'procr-001-closed', 'PROCR-001: Closed', 'Closed')
      write_status_risk('process', 'procr-002-open', 'PROCR-002: Open', 'Mitigating')
      # titled preface -> summary row shows the title (ENH-221)
      write_file('myproject/risks/product/overview.md', <<~MD)
        ---
        title: Product Risk Register
        ---

        # Product Risk Register
      MD
      # preface without a frontmatter title -> summary row falls back to the folder name
      write_file('myproject/risks/process/overview.md', <<~MD)
        # Process Risks
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> The top menu gains a Risks button leading to the summary page. >[SRS-172] </REQ>
    it 'adds the Risks link to the index page top-nav' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/index.html')))
      link = doc.at_css('#risks_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('risks/overview.html')
      expect(link.text).to include('Risks')
    end

    # <REQ> The button appears on every rendered page with a depth-correct href. >[SRS-172] </REQ>
    it 'adds the Risks link to specification pages and the summary page itself' do
      spec_doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      expect(spec_doc.at_css('#risks_menu_item')['href']).to eq('../../risks/overview.html')
      summary_doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/overview.html')))
      expect(summary_doc.at_css('#risks_menu_item')['href']).to eq('overview.html')
    end

    # <REQ> One row per registry; the cell shows the preface's frontmatter title, falling back
    # to the folder name when no preface title exists, linked to the registry page. >[SRS-172] </REQ>
    it 'renders one row per registry, titled by the preface, linking to the registry pages' do
      table = summary_table('myproject/build/risks/overview.html')
      links = table.css('td a.external')
      texts = links.to_h { |a| [a['id'], a.text.strip] }
      expect(texts).to eq('product' => 'Product Risk Register', 'process' => 'process')
      hrefs = links.to_h { |a| [a['id'], a['href']] }
      expect(hrefs['product']).to eq('./product/overview.html')
      expect(hrefs['process']).to eq('./process/overview.html')
    end

    # Every count column after the leading Risk Registry column carries the fixed
    # 7% width, following the Index page's inline-width pattern (ADR-223).
    it 'gives the count cells a fixed 7% width and the registry cell none' do
      table = summary_table('myproject/build/risks/overview.html')
      %w[product process].each do |name|
        cells = registry_row_cells(table, name)
        expect(cells.first['style'].to_s).not_to include('width')
        cells[1..].each { |td| expect(td['style']).to include('width: 7%') }
      end
    end

    # <REQ> Total counts every record; Open excludes Closed; unmarked records count as open. >[SRS-172] </REQ>
    it 'computes the total and open counts from the lifecycle markers' do
      table = summary_table('myproject/build/risks/overview.html')
      product_cells = registry_row_cells(table, 'product').map { |td| td.text.strip }
      expect(product_cells[1]).to eq('4') # Total
      expect(product_cells[2]).to eq('3') # Open: Closed excluded, unmarked counts
      process_cells = registry_row_cells(table, 'process').map { |td| td.text.strip }
      expect(process_cells[1]).to eq('2')
      expect(process_cells[2]).to eq('1')
    end

    # <REQ> Highest and Average RPN over the leading group, ignoring blank values. >[SRS-172] </REQ>
    it 'aggregates the leading RPN group ignoring the blank record' do
      table = summary_table('myproject/build/risks/overview.html')
      product_cells = registry_row_cells(table, 'product').map { |td| td.text.strip }
      expect(product_cells[3]).to eq('120')
      expect(product_cells[4]).to eq('62') # (48 + 120 + 18) / 3
    end

    # <REQ> The Highest RPN cell keeps the leading group's threshold colouring. >[SRS-172] </REQ>
    it 'colours the Highest RPN cell by the leading group thresholds' do
      table = summary_table('myproject/build/risks/overview.html')
      highest_cell = registry_row_cells(table, 'product')[3]
      expect(highest_cell['class']).to include('rpn_unacceptable')
    end

    # <REQ> Both aggregate cells are blank for a registry without RPN configuration. >[SRS-172] </REQ>
    it 'leaves the aggregates blank for the unconfigured registry' do
      table = summary_table('myproject/build/risks/overview.html')
      process_cells = registry_row_cells(table, 'process')
      expect(process_cells[3].text.strip).to eq('')
      expect(process_cells[4].text.strip).to eq('')
      expect(process_cells[3]['class']).not_to include('rpn_unacceptable')
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

    # <REQ> The button is emitted only when at least one registry exists. >[SRS-172] </REQ>
    it 'adds no Risks link to the index page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/index.html')))
      expect(doc.at_css('#risks_menu_item')).to be_nil
    end

    it 'creates no summary page' do
      expect(File.exist?(expand_path('myproject/build/risks/overview.html'))).to be false
    end
  end
end
