# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'almirah create', type: :aruba do
  context 'when scaffolding a new project' do
    before do
      run_command_and_stop('almirah create myproject')
    end

    it 'scaffolds an example decision record under decisions/' do
      expect(File.exist?(expand_path('myproject/decisions/adr-001-start-project-decision.md'))).to be true
    end

    context 'and then building it with please' do
      before do
        run_command_and_stop('almirah please myproject')
      end

      it 'renders the decisions overview page' do
        expect(File.exist?(expand_path('myproject/build/decisions/overview.html'))).to be true
      end

      it 'lists the example decision record on the overview page' do
        doc = Nokogiri::HTML(File.read(expand_path('myproject/build/decisions/overview.html')))
        anchor_ids = doc.xpath('//td[@class="item_id"]//a').map { |a| a['id'] }
        types = doc.xpath('//td[@class="item_type"]').map { |c| c.text.strip }
        titles = doc.xpath('//td[@class="item_text"]').map { |c| c.text.strip }
        expect(anchor_ids).to contain_exactly('adr-001')
        expect(types).to contain_exactly('ADR')
        expect(titles).to contain_exactly('ADR-001: Start Project Decision')
      end

      it 'renders the example decision page' do
        expect(File.exist?(expand_path('myproject/build/decisions/adr-001.html'))).to be true
      end

      it 'links the example decision to REQ-001 from the requirements page' do
        doc = Nokogiri::HTML(File.read(expand_path('myproject/build/specifications/req/req.html')))
        row = doc.css('table.controlled tr').find { |tr| tr.css('td.item_id a[name="REQ-001"]').any? }
        dr_link = row.css('td').last.css('a').first
        expect(dr_link.text.strip).to eq('ADR-001')
        expect(dr_link['href']).to eq('./../../decisions/adr-001.html')
      end
    end
  end
end
