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

    it 'renders build/decisions/overview.html' do
      expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be true
    end

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

  context 'when a decision record has no frontmatter title' do
    before do
      write_file('myproject/project.yml', <<~YML)
        specifications:
          input: []
      YML
      write_file('myproject/decisions/adr-001-titleless.md', "body without frontmatter or heading\n")
      run_command_and_stop('almirah please myproject')
    end

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
