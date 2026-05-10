# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Statistics', type: :aruba do
  before do
    write_file('myproject/project.yml', <<~YML)
      specifications:
        input: []
    YML
    write_file('myproject/specifications/req/req.md', <<~MD)
      # Requirements

      [REQ-001] Controlled item #1.

      [REQ-002] Controlled item #2.

      Non-controlled item in REQ specification.

    MD
    write_file('myproject/specifications/arch/arch.md', <<~MD)
      # Architecture

      [ARCH-001] Controlled item with external reference from a Controlled Item to external Controlled Item >[REQ-001]

      Non-controlled item in ARCH specification.
      
    MD
    run_command_and_stop('almirah please myproject')
  end

  # <REQ> The software shall provide the "Number of Controlled Items" for each specification ID >[SRS-005] </REQ>
  describe 'Number of Controlled Items' do
    let(:idx) { Nokogiri::HTML(File.read(expand_path('myproject/build/index.html'))) }

    it 'renders 2 items for REQ' do
      cell = idx.at_xpath('//tr[.//a[contains(@href,"specifications/req/req.html")]]//td[@class="item_id"]')
      expect(cell).not_to be_nil
      expect(cell.text.strip).to eq('2')
    end

    it 'renders 1 item for ARCH' do
      cell = idx.at_xpath('//tr[.//a[contains(@href,"specifications/arch/arch.html")]]//td[@class="item_id"]')
      expect(cell).not_to be_nil
      expect(cell.text.strip).to eq('1')
    end
  end

  # <REQ> The software shall provide the "Number of Items w/ Down-links" for each specification >[SRS-007] </REQ>
  describe 'Number of Items with Down-links' do
    let(:idx) { Nokogiri::HTML(File.read(expand_path('myproject/build/index.html'))) }

    it 'renders 1 down-link item for REQ' do
      cell = idx.at_xpath('(//tr[.//a[contains(@href,"specifications/req/req.html")]]//td[@class="item_id"])[3]')
      expect(cell).not_to be_nil
      expect(cell.text.strip).to eq('1')
    end

    it 'renders 0 down-link items for ARCH' do
      cell = idx.at_xpath('(//tr[.//a[contains(@href,"specifications/arch/arch.html")]]//td[@class="item_id"])[3]')
      expect(cell).not_to be_nil
      expect(cell.text.strip).to eq('0')
    end
  end

  # <REQ> The software shall provide the "Number of Items w/ Up-links" for each specification >[SRS-006] </REQ>
  describe 'Number of Items with Up-links' do
    let(:idx) { Nokogiri::HTML(File.read(expand_path('myproject/build/index.html'))) }

    it 'renders 0 up-link items for REQ' do
      cell = idx.at_xpath('(//tr[.//a[contains(@href,"specifications/req/req.html")]]//td[@class="item_id"])[2]')
      expect(cell).not_to be_nil
      expect(cell.text.strip).to eq('0')
    end

    it 'renders 1 up-link item for ARCH' do
      cell = idx.at_xpath('(//tr[.//a[contains(@href,"specifications/arch/arch.html")]]//td[@class="item_id"])[2]')
      expect(cell).not_to be_nil
      expect(cell.text.strip).to eq('1')
    end
  end
end
