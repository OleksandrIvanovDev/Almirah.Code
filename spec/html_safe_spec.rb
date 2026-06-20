# frozen_string_literal: true

require_relative '../lib/almirah/html_safe'

describe 'HtmlSafe' do
  let(:helper) { Class.new { include HtmlSafe }.new }

  describe '#escape_text' do
    it 'escapes the five sensitive characters' do
      expect(helper.escape_text(%(<a href="x" data='y'> & </a>)))
        .to eq('&lt;a href=&quot;x&quot; data=&#39;y&#39;&gt; &amp; &lt;/a&gt;')
    end

    it 'leaves plain text untouched' do
      expect(helper.escape_text('Hello World!')).to eq('Hello World!')
    end

    it 'neutralises a script element' do
      expect(helper.escape_text('<script>alert(1)</script>'))
        .to eq('&lt;script&gt;alert(1)&lt;/script&gt;')
    end
  end

  describe '#escape_attr' do
    it 'escapes quotes so a value cannot break out of an attribute' do
      expect(helper.escape_attr('" onerror="alert(1)'))
        .to eq('&quot; onerror=&quot;alert(1)')
    end
  end

  describe '#safe_url' do
    it 'admits relative paths' do
      expect(helper.safe_url('img/diagram.svg')).to eq('img/diagram.svg')
    end

    it 'admits anchor references' do
      expect(helper.safe_url('#section-2')).to eq('#section-2')
    end

    it 'admits http, https and mailto' do
      expect(helper.safe_url('http://example.com')).to eq('http://example.com')
      expect(helper.safe_url('https://example.com')).to eq('https://example.com')
      expect(helper.safe_url('mailto:a@b.c')).to eq('mailto:a@b.c')
    end

    it 'rejects javascript, data and vbscript schemes' do
      expect(helper.safe_url('javascript:alert(1)')).to be_nil
      expect(helper.safe_url('data:text/html,<script>')).to be_nil
      expect(helper.safe_url('vbscript:msgbox(1)')).to be_nil
    end

    it 'is case-insensitive about the scheme' do
      expect(helper.safe_url('JaVaScRiPt:alert(1)')).to be_nil
      expect(helper.safe_url('HTTPS://example.com')).to eq('HTTPS://example.com')
    end
  end
end
