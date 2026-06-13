# frozen_string_literal: true

require_relative '../lib/almirah/link_registry'

RSpec.describe LinkRegistry do
  subject(:registry) { described_class.new }

  # Minimal stand-in for a managed document (id + optional source path).
  let(:doc_class) { Struct.new(:id, :path, :output_rel_path) }

  it 'finds a document by id, case-insensitively' do
    doc = doc_class.new('ADR-185', '/proj/decisions/adr-185-status.md', 'decisions/adr-185.html')
    registry.register(doc)
    expect(registry.find_by_id('adr-185')).to equal(doc)
    expect(registry.find_by_id('ADR-185')).to equal(doc)
  end

  it 'finds a document by its absolute source path' do
    doc = doc_class.new('srs', '/proj/specifications/srs/srs.md', 'specifications/srs/srs.html')
    registry.register(doc)
    expect(registry.find_by_source('/proj/specifications/srs/srs.md')).to equal(doc)
  end

  it 'resolves a decision by id regardless of its folder' do
    doc = doc_class.new('adr-200', '/proj/decisions/release 0.4.0/adr-200-x.md', 'decisions/release 0.4.0/adr-200.html')
    registry.register(doc)
    expect(registry.find_by_id('adr-200')).to equal(doc)
  end

  it 'also finds a document by its full filename stem, not only its id (SRS-090)' do
    doc = doc_class.new('adr-170', '/proj/decisions/adr-170-introduce-decision-records.md', 'decisions/adr-170.html')
    registry.register(doc)
    expect(registry.find_by_id('adr-170')).to equal(doc)
    expect(registry.find_by_id('adr-170-introduce-decision-records')).to equal(doc)
    expect(registry.collisions).to be_empty
  end

  it 'does not index a source path for a document without one' do
    doc = doc_class.new('index', nil, 'index.html')
    registry.register(doc)
    expect(registry.find_by_id('index')).to equal(doc)
    expect(registry.find_by_source('/anything')).to be_nil
  end

  it 'records a collision when two distinct documents share an id' do
    registry.register(doc_class.new('dup', '/a/dup.md', 'a/dup.html'))
    registry.register(doc_class.new('dup', '/b/dup.md', 'b/dup.html'))
    expect(registry.collisions).to include('dup')
  end

  it 'does not flag a collision when the same document is registered twice' do
    doc = doc_class.new('srs', '/proj/specifications/srs/srs.md', 'specifications/srs/srs.html')
    registry.register(doc)
    registry.register(doc)
    expect(registry.collisions).to be_empty
  end
end
