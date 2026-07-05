# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Paragraph Types', type: :aruba do
  before do
    write_file('myproject/project.yml', <<~YML)
      specifications:
        input: []
    YML
    write_file('myproject/specifications/req/req.md', <<~MD)
      # Requirements

      [REQ-001] Controlled item.

      Non-controlled item in REQ specification.

    MD
    write_file('myproject/specifications/arch/arch.md', <<~MD)
      # Architecture

      [ARCH-001] Controlled item with external reference from a Controlled Item to external Controlled Item >[REQ-001]

      Non-controlled item in ARCH specification.

    MD
    run_command_and_stop('almirah please myproject')
  end

  describe 'output file existence' do
    it 'creates the index HTML file' do
      expect(File.exist?(expand_path('myproject/build/index.html'))).to be true
    end

    it 'creates the specification HTML files' do
      expect(File.exist?(expand_path('myproject/build/specifications/req/req.html'))).to be true
      expect(File.exist?(expand_path('myproject/build/specifications/arch/arch.html'))).to be true
    end
  end

  # <REQ>The software shall allow creating Controlled Items >[SRS-001]</REQ>
  describe 'controlled item' do
    let(:req) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html'))) }
    let(:arch) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/arch/arch.html'))) }

    it 'renders REQ-001 with the correct id attribute' do
      expect(req.at_css('[id="REQ-001"]')).not_to be_nil
    end

    it 'wraps REQ-001 in an anchor tag' do
      expect(req.at_css('a[id="REQ-001"]')).not_to be_nil
    end

    it 'renders ARCH-001 with the correct id attribute' do
      expect(arch.at_css('[id="ARCH-001"]')).not_to be_nil
    end

    it 'wraps ARCH-001 in an anchor tag' do
      expect(arch.at_css('a[id="ARCH-001"]')).not_to be_nil
    end
  end

  # <REQ>The software shall allow to create a non-controlled items >[SRS-004]</REQ>
  describe 'non-controlled item' do
    let(:req) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html'))) }
    let(:arch) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/arch/arch.html'))) }

    it 'renders Non-controlled item in REQ specification' do
      expect(req.at_xpath('//p[contains(., "Non-controlled item in REQ specification.")]')).not_to be_nil
    end

    it 'renders Non-controlled item in ARCH specification' do
      expect(arch.at_xpath('//p[contains(., "Non-controlled item in ARCH specification.")]')).not_to be_nil
    end
  end

  # <REQ> The software shall allow to create a reference from a Controlled Item to external Controlled Item >[SRS-002] </REQ>
  describe 'reference from controlled item' do
    let(:req) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html'))) }
    let(:arch) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/arch/arch.html'))) }

    it 'renders ARCH-001 with the up-link to REQ-001' do
      expect(arch.at_css('a[href="./../req/req.html#REQ-001"][title="Linked to"]')).not_to be_nil
    end
  end

  # <REQ> The software shall indicate whether a Controlled Item is referenced in another specification via External Item ID >[SRS-003] </REQ>
  describe 'reference to controlled item' do
    let(:req) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html'))) }
    let(:arch) { Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/arch/arch.html'))) }

    it 'renders REQ-001 with the down-link to ARCH-001' do
      expect(req.at_css('a[href="./../arch/arch.html#ARCH-001"][title="Referenced in"]')).not_to be_nil
    end
  end
end
