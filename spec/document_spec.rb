describe 'Document' do # rubocop:disable Metrics/BlockLength
  it 'Is able to build sections tree for Heading1' do
    input_lines = []
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
  end

  it 'Is able to build sections tree for Heading1 and Heading1' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 2
  end

  it 'Is able to build sections tree for Heading1 with Document Title' do
    input_lines = []
    input_lines << '% Document Title'
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 0
    expect(dom.root_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
  end

  it 'Is able to build sections tree for Heading1 and Heading2' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '## Heading Level 2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 2
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq(dom.root_section)
  end
  it 'Is able to build sections tree for Heading1 and Heading3' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '### Heading Level 3'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 3
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 3'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq(dom.root_section)
  end
  it 'Is able to build sections tree for Heading1, Heading2, and Heading3' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '## Heading Level 2'
    input_lines << '### Heading Level 3'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 2
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq(dom.root_section)
    # Heading 3
    expect(dom.root_section.sections[0].sections[0].sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[0].sections[0].heading.text).to eq 'Heading Level 3'
    expect(dom.root_section.sections[0].sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[0].sections[0].parent_section.parent_section).to \
        eq(dom.root_section.sections[0])
  end
  it 'Is able to build sections tree for Heading1, Heading2, and Heading2' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '## Heading Level 2.1'
    input_lines << '## Heading Level 2.2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 2
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 2.1'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq(dom.root_section)
    # Heading 2
    expect(dom.root_section.sections[0].sections[1].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[1].heading.text).to eq 'Heading Level 2.2'
    expect(dom.root_section.sections[0].sections[1].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[1].parent_section.parent_section).to eq(dom.root_section)
  end
  it 'Is able to build sections tree for Doc Title, Heading1, and Heading1' do
    input_lines = []
    input_lines << '% Document Title'
    input_lines << '# Heading Level 1.1'
    input_lines << '# Heading Level 1.2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 0
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 2
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1.1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 1
    expect(dom.root_section.sections[1].heading.level).to eq 1
    expect(dom.root_section.sections[1].heading.text).to eq 'Heading Level 1.2'
    expect(dom.root_section.sections[1].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[1].parent_section.parent_section).to be_nil
  end
  it 'Is able to build sections tree for Doc Title, Heading2, and Heading2' do
    input_lines = []
    input_lines << '% Document Title'
    input_lines << '## Heading Level 2.1'
    input_lines << '## Heading Level 2.2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 0
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 2
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 2
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 2.1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 1
    expect(dom.root_section.sections[1].heading.level).to eq 2
    expect(dom.root_section.sections[1].heading.text).to eq 'Heading Level 2.2'
    expect(dom.root_section.sections[1].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[1].parent_section.parent_section).to be_nil
  end
  it 'Is able to build sections tree for Doc Title, Heading2, and Heading1' do
    input_lines = []
    input_lines << '% Document Title'
    input_lines << '## Heading Level 2'
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 0
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 2
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 2
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 1
    expect(dom.root_section.sections[1].heading.level).to eq 1
    expect(dom.root_section.sections[1].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[1].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[1].parent_section.parent_section).to be_nil
  end
  it 'Is able to build sections tree for Doc Title, Heading3, and Heading1' do
    input_lines = []
    input_lines << '% Document Title'
    input_lines << '### Heading Level 3'
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 0
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 2
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 3'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[0].parent_section.parent_section).to be_nil
    # Heading 1
    expect(dom.root_section.sections[1].heading.level).to eq 1
    expect(dom.root_section.sections[1].heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[1].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[1].parent_section.parent_section).to be_nil
  end
  it 'Is able to build sections tree for Heading1, Heading3, and Heading2' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '### Heading Level 3'
    input_lines << '## Heading Level 2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 3'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq dom.root_section
    # Heading 1
    expect(dom.root_section.sections[0].sections[1].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[1].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[1].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[1].parent_section.parent_section).to eq dom.root_section
  end
  it 'Is able to build sections tree for Heading1, Heading3, Heading3, and Heading2' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '### Heading Level 3.1'
    input_lines << '### Heading Level 3.2'
    input_lines << '## Heading Level 2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 3.1'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq dom.root_section
    # Heading 3.2
    expect(dom.root_section.sections[0].sections[1].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[1].heading.text).to eq 'Heading Level 3.2'
    expect(dom.root_section.sections[0].sections[1].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[1].parent_section.parent_section).to eq dom.root_section
    # Heading 2
    expect(dom.root_section.sections[0].sections[2].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[2].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[2].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[2].parent_section.parent_section).to eq dom.root_section
  end
  it 'Is able to build sections tree for Heading1, Heading3, Heading2, and Heading3' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '### Heading Level 3.1'
    input_lines << '## Heading Level 2'
    input_lines << '### Heading Level 3.2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 1
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 1
    # Root Sub-heading
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 3.1'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq dom.root_section
    # Heading 2
    expect(dom.root_section.sections[0].sections[1].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[1].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[1].parent_section.heading.text).to eq 'Heading Level 1'
    expect(dom.root_section.sections[0].sections[1].parent_section.parent_section).to eq dom.root_section
    # Heading 3.2
    expect(dom.root_section.sections[0].sections[1].sections[0].heading.level).to eq 3
    expect(dom.root_section.sections[0].sections[1].sections[0].heading.text).to eq 'Heading Level 3.2'
    expect(dom.root_section.sections[0].sections[1].sections[0].parent_section.heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[1].sections[0].parent_section).to \
      eq dom.root_section.sections[0].sections[1]
  end
  it 'Is able to build sections tree for Doc Title, Heading1, Heading2, and Heading1' do
    input_lines = []
    input_lines << '% Document Title'
    input_lines << '# Heading Level 1.1'
    input_lines << '## Heading Level 2'
    input_lines << '# Heading Level 1.2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    dom = Document.new(doc.headings)
    expect(dom.root_section.heading.level).to eq 0
    expect(dom.root_section.parent_section).to be_nil
    expect(dom.root_section.sections.length).to be 2
    # Root Sub-heading
    expect(dom.root_section.sections[0].heading.level).to eq 1
    expect(dom.root_section.sections[0].heading.text).to eq 'Heading Level 1.1'
    expect(dom.root_section.sections[0].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[0].parent_section).to eq dom.root_section
    # Heading 2
    expect(dom.root_section.sections[0].sections[0].heading.level).to eq 2
    expect(dom.root_section.sections[0].sections[0].heading.text).to eq 'Heading Level 2'
    expect(dom.root_section.sections[0].sections[0].parent_section.heading.text).to eq 'Heading Level 1.1'
    expect(dom.root_section.sections[0].sections[0].parent_section.parent_section).to eq dom.root_section
    # Heading 1
    expect(dom.root_section.sections[1].heading.level).to eq 1
    expect(dom.root_section.sections[1].heading.text).to eq 'Heading Level 1.2'
    expect(dom.root_section.sections[1].parent_section.heading.text).to eq 'Document Title'
    expect(dom.root_section.sections[1].parent_section).to eq dom.root_section
  end
end
