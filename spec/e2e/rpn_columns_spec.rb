# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the RPN computed columns introduced by ADR-217: named per-registry
# groups append "<Name> RPN" columns whose cells are the product of the
# record's numeric input sections, blank when any input is missing or not
# numeric, coloured by the group's acceptable/unacceptable thresholds.
RSpec.describe 'RPN Computed Columns', type: :aruba do
  def register_table(project_html_path)
    doc = Nokogiri::HTML(File.read(expand_path(project_html_path)))
    doc.at_css('table.risk_register')
  end

  def header_cells(table)
    table.css('thead th').map { |th| th.text.strip }
  end

  # The td holding the given record's cell for the given header, by position.
  def cell_for(table, record_id, header)
    column_index = header_cells(table).index(header)
    row = table.at_css("a[id=\"#{record_id}\"]").ancestors('tr').first
    row.css('td')[column_index]
  end

  def write_fmea_record(id, title, factors, residual: nil)
    severity, occurrence, detection = factors
    residual_sections = residual ? <<~RES : ''

      # Residual Severity

      #{residual[0]}

      # Residual Occurrence

      #{residual[1]}

      # Residual Detection

      #{residual[2]}
    RES
    write_file("myproject/risks/product/#{id}.md", <<~MD)
      ---
      title: "#{title}"
      ---

      # Severity

      #{severity}

      # Occurrence

      #{occurrence}

      # Detection

      #{detection}
      #{residual_sections}
    MD
  end

  context 'when a registry configures a three-factor FMEA group with thresholds' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: product
            columns: [Severity, Occurrence, Detection, Status]
            rpn:
              - name: Initial
                inputs: [Severity, Occurrence, Detection]
                thresholds:
                  acceptable: 20
                  unacceptable: 100
      YML
      write_fmea_record('prodr-001-mid', 'PRODR-001: Caution Band', [8, 3, 2])     # 48 -> caution
      write_fmea_record('prodr-002-low', 'PRODR-002: Acceptable Band', [2, 3, 3])  # 18 -> acceptable
      write_fmea_record('prodr-003-high', 'PRODR-003: Unacceptable Band', [10, 6, 2]) # 120 -> unacceptable
      write_file('myproject/risks/product/prodr-004-tbd.md', <<~MD)
        ---
        title: "PRODR-004: Not Yet Analysed"
        ---

        # Severity

        8

        # Occurrence

        TBD

        # Detection

        2
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> One computed column per group, headed "<Name> RPN", after the configured columns. >[SRS-169] </REQ>
    it 'appends the named RPN column after the configured columns' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(header_cells(table)).to eq(['#', 'Title', 'Severity', 'Occurrence', 'Detection', 'Status',
                                         'Initial RPN'])
    end

    # <REQ> The cell value is the product of the record's numeric input sections. >[SRS-169] </REQ>
    it 'computes the product of the three factors' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(cell_for(table, 'prodr-001', 'Initial RPN').text.strip).to eq('48')
      expect(cell_for(table, 'prodr-002', 'Initial RPN').text.strip).to eq('18')
      expect(cell_for(table, 'prodr-003', 'Initial RPN').text.strip).to eq('120')
    end

    # <REQ> Blank, never zero, when any input is missing or not numeric. >[SRS-169] </REQ>
    it 'renders a blank cell when a factor is not numeric' do
      table = register_table('myproject/build/risks/product/overview.html')
      cell = cell_for(table, 'prodr-004', 'Initial RPN')
      expect(cell.text.strip).to eq('')
      expect(cell['class']).not_to include('rpn_')
    end

    # <REQ> Threshold colouring: acceptable at/below, unacceptable at/above, caution between. >[SRS-170] </REQ>
    it 'colours the three bands by the configured thresholds' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(cell_for(table, 'prodr-002', 'Initial RPN')['class']).to include('rpn_acceptable')
      expect(cell_for(table, 'prodr-001', 'Initial RPN')['class']).to include('rpn_caution')
      expect(cell_for(table, 'prodr-003', 'Initial RPN')['class']).to include('rpn_unacceptable')
    end

    # <REQ> Boundary values: at the acceptable bound is acceptable, at the unacceptable bound is unacceptable. >[SRS-170] </REQ>
    it 'treats the bounds themselves as acceptable and unacceptable' do
      write_fmea_record('prodr-005-edge-low', 'PRODR-005: At Acceptable', [5, 2, 2]) # 20
      write_fmea_record('prodr-006-edge-high', 'PRODR-006: At Unacceptable', [10, 5, 2]) # 100
      run_command_and_stop('almirah please myproject')
      table = register_table('myproject/build/risks/product/overview.html')
      expect(cell_for(table, 'prodr-005', 'Initial RPN')['class']).to include('rpn_acceptable')
      expect(cell_for(table, 'prodr-006', 'Initial RPN')['class']).to include('rpn_unacceptable')
    end
  end

  context 'when a registry configures an initial-plus-residual group pair' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: product
            columns: [Severity, Occurrence, Detection, Status]
            rpn:
              - name: Initial
                inputs: [Severity, Occurrence, Detection]
              - name: Residual
                inputs: [Residual Severity, Residual Occurrence, Residual Detection]
      YML
      write_fmea_record('prodr-001-mitigated', 'PRODR-001: Mitigated', [8, 3, 2], residual: [4, 2, 2])
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Groups append in configured order; inputs may name unsurfaced sections. >[SRS-169] </REQ>
    it 'appends both groups in configured order and computes each from its own inputs' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(header_cells(table).last(2)).to eq(['Initial RPN', 'Residual RPN'])
      expect(cell_for(table, 'prodr-001', 'Initial RPN').text.strip).to eq('48')
      expect(cell_for(table, 'prodr-001', 'Residual RPN').text.strip).to eq('16')
      expect(header_cells(table)).not_to include('Residual Severity')
    end

    # <REQ> No thresholds configured — the cell is uncoloured. >[SRS-170] </REQ>
    it 'leaves the cells uncoloured without thresholds' do
      table = register_table('myproject/build/risks/product/overview.html')
      expect(cell_for(table, 'prodr-001', 'Initial RPN')['class']).to eq('item_rpn')
      expect(cell_for(table, 'prodr-001', 'Residual RPN')['class']).to eq('item_rpn')
    end
  end

  context 'when a group has a single input' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
        risks:
          - folder: security
            columns: [Threat, Status]
            rpn:
              - name: Score
                inputs: [CVSS Score]
      YML
      write_file('myproject/risks/security/secr-001-injection.md', <<~MD)
        ---
        title: "SECR-001: SQL Injection"
        ---

        # Threat

        Unsanitised search input.

        # CVSS Score

        9.8
      MD
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> A single-input group surfaces the precomputed score unchanged. >[SRS-169] </REQ>
    it 'surfaces the sections value unchanged as the RPN column' do
      table = register_table('myproject/build/risks/security/overview.html')
      expect(header_cells(table).last).to eq('Score RPN')
      expect(cell_for(table, 'secr-001', 'Score RPN').text.strip).to eq('9.8')
    end
  end
end
