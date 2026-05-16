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
        # ADR-001: First Decision

        ## Context

        A first decision.
      MD
      write_file('myproject/decisions/adr-002-bar.md', <<~MD)
        # ADR-002: Second Decision

        ## Context

        A second decision.
      MD
      write_file('myproject/decisions/README.txt', 'ignored non-markdown file')
      run_command_and_stop('almirah please myproject')
    end

    it 'renders build/decisions/overview.html' do
      expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be true
    end

    it 'lists all parsed decision records on the overview page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      ids = doc.xpath('//td[@class="item_id"]').map { |c| c.text.strip }
      titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
      expect(ids).to contain_exactly('adr-001-foo', 'adr-002-bar')
      expect(titles).to contain_exactly('ADR-001: First Decision', 'ADR-002: Second Decision')
    end

    it 'adds the Decision Records link to the index page top-nav' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/index.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('./decisions/overview.html')
      expect(link.text).to include('Decision Records')
      expect(link.at_css('i')['class']).to include('fa-gavel')
    end

    it 'adds the Decision Records link to specification page top-nav with correct relative path' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('./../../decisions/overview.html')
    end

    it 'adds the Decision Records link to the overview page itself' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      link = doc.at_css('#decisions_menu_item')
      expect(link).not_to be_nil
      expect(link['href']).to eq('./overview.html')
    end
  end

  context 'when a decision record has no H1 heading' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/specifications/req/req.md', "# Requirements\n\n[REQ-001] x\n")
      write_file('myproject/decisions/adr-001-titleless.md', "body without heading\n")
      run_command_and_stop('almirah please myproject')
    end

    it 'falls back to the filename-derived id for the title' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
      titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
      expect(titles).to eq(['adr-001-titleless'])
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

    it 'does not add the Decision Records link to the index page' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/index.html')))
      expect(doc.at_css('#decisions_menu_item')).to be_nil
    end

    it 'does not add the Decision Records link to spec pages' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
      expect(doc.at_css('#decisions_menu_item')).to be_nil
    end
  end
end
