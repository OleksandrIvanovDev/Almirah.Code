# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'HTML output', type: :aruba do
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

  describe 'output file existence' do
    it 'creates the index HTML file' do
      expect(File.exist?(expand_path('myproject/build/index.html'))).to be true
    end

    it 'creates the specification HTML file' do
      expect(File.exist?(expand_path('myproject/build/specifications/req/req.html'))).to be true
    end
  end

  describe 'controlled item DOM id' do
    let(:doc) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html'))) }

    it 'renders REQ-001 with the correct id attribute' do
      expect(doc.at_css('[id="REQ-001"]')).not_to be_nil
    end

    it 'wraps REQ-001 in an anchor tag' do
      expect(doc.at_css('a[id="REQ-001"]')).not_to be_nil
    end
  end
end
