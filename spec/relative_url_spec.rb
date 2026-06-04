# frozen_string_literal: true

require_relative '../lib/almirah/relative_url'

RSpec.describe RelativeUrl do
  describe '.between' do
    it 'links to a sibling page in the same directory' do
      expect(described_class.between('a/b/x.html', 'a/b/y.html')).to eq('y.html')
    end

    it 'links to a page deeper in the tree' do
      expect(described_class.between('a/index.html', 'a/b/y.html')).to eq('b/y.html')
    end

    it 'links to a page higher in the tree' do
      expect(described_class.between('a/b/c/x.html', 'index.html')).to eq('../../../index.html')
    end

    it 'links across sibling subtrees' do
      url = described_class.between('decisions/release 0.4.1/adr-185.html', 'specifications/srs/srs.html')
      expect(url).to eq('../../specifications/srs/srs.html')
    end

    it 'percent-encodes spaces in path segments' do
      url = described_class.between('specifications/srs/srs.html', 'decisions/release 0.4.1/adr-185.html')
      expect(url).to eq('../../decisions/release%200.4.1/adr-185.html')
    end

    it 'appends a non-empty fragment' do
      expect(described_class.between('a/x.html', 'a/y.html', fragment: 'SRS-001')).to eq('y.html#SRS-001')
    end

    it 'ignores a nil or empty fragment' do
      expect(described_class.between('a/x.html', 'a/y.html', fragment: nil)).to eq('y.html')
      expect(described_class.between('a/x.html', 'a/y.html', fragment: '')).to eq('y.html')
    end
  end
end
