# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Cross-document traceability', type: :aruba do
  before do
    write_file('myproject/project.yml', <<~YML)
      specifications:
        input: []
    YML
    write_file('myproject/specifications/req/req.md', <<~MD)
      # Requirements

      [REQ-001] A first requirement.
    MD
    # Protocol with an up-link to REQ-001 via ControlledTable
    write_file('myproject/tests/protocols/tp-001/tp-001.md', <<~MD)
      # Test Protocol TP-001

      ## Test Procedure

      | Step | Description | Expected Result | Req-ID |
      |---|---|---|---|
      | [TP-001-0001] 1 | Verify REQ-001 | Pass | >[REQ-001] |
    MD
    run_command_and_stop('almirah please myproject')
  end

  describe 'protocol HTML output' do
    let(:proto_doc) do
      Nokogiri::HTML(File.read(expand_path('myproject/build/tests/protocols/tp-001/tp-001.html')))
    end

    it 'creates the protocol HTML file' do
      expect(File.exist?(expand_path('myproject/build/tests/protocols/tp-001/tp-001.html'))).to be true
    end

    it 'contains a hyperlink pointing to the REQ-001 anchor in the spec' do
      # controlled_table.rb renders: href="./../../../specifications/req/req.html#REQ-001"
      expect(proto_doc.at_css('a[href*="req.html#REQ-001"]')).not_to be_nil
    end

    it 'the up-link text is REQ-001' do
      link = proto_doc.at_css('a[href*="req.html#REQ-001"]')
      expect(link.text.strip).to eq('REQ-001')
    end
  end

  describe 'index page' do
    let(:index_doc) { Nokogiri::HTML(File.read(expand_path('myproject/build/index.html'))) }

    it 'lists the req specification' do
      # index.rb renders a link to each specification: href="./specifications/req/req.html"
      expect(index_doc.at_css('a[href*="specifications/req/req.html"]')).not_to be_nil
    end
  end
end
