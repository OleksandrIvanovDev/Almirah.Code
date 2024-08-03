# frozen_string_literal: true

describe 'DocParser' do # rubocop:disable Metrics/BlockLength
  it 'Recognizes Heading1' do
    input_lines = []
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[1].level).to eq 1
    expect(doc.items[1].text).to eq 'Heading Level 1'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[1]).to eq(doc.items[1])
    # section number
    expect(doc.headings[1].section_number).to eq '1'
  end

  it 'Recognizes pandoc document title' do
    input_lines = []
    input_lines << '% Heading Level 0'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 2
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'Heading Level 0'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'Heading Level 0'
    # parent doc
    expect(doc.items[0].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
  end

  it 'Recognizes Heading2' do
    input_lines = []
    input_lines << '## Heading Level 2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[1].level).to eq 2
    expect(doc.items[1].text).to eq 'Heading Level 2'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[1]).to eq(doc.items[1])
  end

  it 'Recognizes Heading1 and Heading2' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '## Heading Level 2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(Heading)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[1].level).to eq 1
    expect(doc.items[1].text).to eq 'Heading Level 1'
    expect(doc.items[2].level).to eq 2
    expect(doc.items[2].text).to eq 'Heading Level 2'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[1]).to eq(doc.items[1])
    expect(doc.headings[2]).to eq(doc.items[2])
    expect(doc.headings.length).to eq 3
  end

  it 'Recognizes Heading1 and Heading1' do
    input_lines = []
    input_lines << '# Heading Level 1 - 1'
    input_lines << '# Heading Level 1 - 2'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(Heading)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[1].level).to eq 1
    expect(doc.items[1].text).to eq 'Heading Level 1 - 1'
    expect(doc.items[2].level).to eq 1
    expect(doc.items[2].text).to eq 'Heading Level 1 - 2'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[1]).to eq(doc.items[1])
    expect(doc.headings[2]).to eq(doc.items[2])
    expect(doc.headings.length).to eq 3
  end

  it 'Recognizes Heading1 as a document title for two documents but with correct section number' do
    input_lines = []
    input_lines << '# Heading Level 1'
    doc = Specification.new('C:/srs.md')
    doc2 = Specification.new('C:/arch.md')

    DocParser.parse(doc, input_lines)
    DocParser.parse(doc2, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(DocFooter)

    expect(doc2.items.length).to eq 3
    expect(doc2.items[0]).to be_instance_of(Heading)
    expect(doc2.items[1]).to be_instance_of(Heading)
    expect(doc2.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    expect(doc2.title).to eq 'arch.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[1].level).to eq 1
    expect(doc.items[1].text).to eq 'Heading Level 1'
    expect(doc2.items[1].level).to eq 1
    expect(doc2.items[1].text).to eq 'Heading Level 1'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    expect(doc2.items[1].parent_doc).to eq(doc2)
    # headings
    expect(doc.headings[1]).to eq(doc.items[1])
    expect(doc2.headings[1]).to eq(doc2.items[1])
    # section number
    expect(doc.headings[1].section_number).to eq '1'
    expect(doc2.headings[1].section_number).to eq '1'
  end

  it 'Recognizes Controlled Paragraph out of any section' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph'
    expect(doc.items[1].id).to eq 'SRS-001'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Recognizes Controlled Paragraph with id in lower case as well' do
    input_lines = []
    input_lines << '[srs-001] This is a Controlled Paragraph'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph'
    expect(doc.items[1].id).to eq 'SRS-001'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Recognizes Controlled Paragraph within a section' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '[SRS-001] This is a Controlled Paragraph'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(ControlledParagraph)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[2].text).to eq 'This is a Controlled Paragraph'
    expect(doc.items[2].id).to eq 'SRS-001'
    # parent doc
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.items[2].parent_heading).to eq(doc.items[1])
  end

  it 'Recognizes Controlled Paragraph with up-link' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with up-link >[SYS-002]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with up-link'
    expect(doc.items[1].id).to eq 'SRS-001'
    # up-link
    expect(doc.items[1].up_link_ids[0]).to eq 'SYS-002'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end
  it 'Recognizes Controlled Paragraph with up-link even in lower case' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with up-link >[sys-002]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with up-link'
    expect(doc.items[1].id).to eq 'SRS-001'
    # up-link
    expect(doc.items[1].up_link_ids[0]).to eq 'SYS-002'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
    # references
    expect(doc.dictionary).to have_key('SRS-001')
    expect(doc.controlled_items[0]).to eq(doc.items[1])
    expect(doc.last_used_id).to eq('SRS-001')
    expect(doc.items_with_uplinks_number).to eq 1
  end
  it 'Recognizes Controlled Paragraph and maintains all required refereces' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with up-link >[SYS-002]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # references
    expect(doc.dictionary).to have_key('SRS-001')
    expect(doc.controlled_items[0]).to eq(doc.items[1])
    expect(doc.last_used_id).to eq('SRS-001')
    expect(doc.items_with_uplinks_number).to eq 1
    expect(doc.duplicated_ids_number).to eq 0
    # document ids are always in lower case
    expect(doc.id).to eq('srs')
    expect(doc.up_link_docs).to have_key('sys')
  end
  it 'Recognizes Controlled Paragraph with duplicated ids' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with up-link >[SYS-002]'
    input_lines << '[srs-001] This is a duplicated Controlled Paragraph'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(ControlledParagraph)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with up-link'
    expect(doc.items[1].id).to eq 'SRS-001'
    expect(doc.items[2].text).to eq 'This is a duplicated Controlled Paragraph'
    expect(doc.items[2].id).to eq 'SRS-001'
    # references
    expect(doc.dictionary).to have_key('SRS-001')
    expect(doc.controlled_items[0]).to eq(doc.items[1])
    expect(doc.controlled_items[1]).to eq(doc.items[2])
    expect(doc.last_used_id).to eq('SRS-001')
    expect(doc.items_with_uplinks_number).to eq 1
    expect(doc.duplicated_ids_number).to eq 1
    # document ids are always in lower case
    expect(doc.id).to eq('srs')
    expect(doc.up_link_docs).to have_key('sys')
  end
  it 'Recognizes Controlled Paragraph with two up-links' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with two up-links >[SYS-002], >[SYS-003]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with two up-links'
    expect(doc.items[1].id).to eq 'SRS-001'
    # up-link
    expect(doc.items[1].up_link_ids[0]).to eq 'SYS-002'
    expect(doc.items[1].up_link_ids[1]).to eq 'SYS-003'
    # reference
    expect(doc.up_link_docs).to have_key('sys')
  end
  it 'Recognizes Controlled Paragraph with two same up-links' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with two same up-links >[SYS-002], >[SYS-002]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with two same up-links'
    expect(doc.items[1].id).to eq 'SRS-001'
    # up-link
    expect(doc.items[1].up_link_ids[0]).to eq 'SYS-002'
    expect(doc.items[1].up_link_ids.length).to eq 1
    # reference
    expect(doc.up_link_docs).to have_key('sys')
  end
  it 'Recognizes Controlled Paragraph with recursive up-links' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with recursive up-links >[SRS-001], >[SYS-002]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with recursive up-links'
    expect(doc.items[1].id).to eq 'SRS-001'
    # up-link
    expect(doc.items[1].up_link_ids[0]).to eq 'SYS-002'
    expect(doc.items[1].up_link_ids.length).to eq 1
    # reference
    expect(doc.up_link_docs).to have_key('sys')
    expect(doc.up_link_docs.size).to eq 1
  end
  it 'Recognizes Controlled Paragraph with up-links to several docs' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph with up-links to several docs >[SYS-100], >[ARCH-200], >[PRD-300]'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Text and id (id is in uppercase)
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph with up-links to several docs'
    expect(doc.items[1].id).to eq 'SRS-001'
    # up-link
    expect(doc.items[1].up_link_ids[0]).to eq 'SYS-100'
    expect(doc.items[1].up_link_ids[1]).to eq 'ARCH-200'
    expect(doc.items[1].up_link_ids[2]).to eq 'PRD-300'
    expect(doc.items[1].up_link_ids.length).to eq 3
    # reference
    expect(doc.up_link_docs).to have_key('sys')
    expect(doc.up_link_docs).to have_key('arch')
    expect(doc.up_link_docs).to have_key('prd')
    expect(doc.up_link_docs.size).to eq 3
  end

  it 'Recognizes Markdown Table out of any section' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '|---|---|'
    input_lines << '| Column A1 | Column B1 |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A1 | Column B3 |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(MarkdownTable)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].column_names.length).to eq 2
    expect(doc.items[1].rows.length).to eq 3
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Recognizes Markdown Table within a section' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '|---|---|'
    input_lines << '| Column A1 | Column B1 |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A1 | Column B3 |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(MarkdownTable)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[2].column_names.length).to eq 2
    expect(doc.items[2].rows.length).to eq 3
    # parent doc
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.items[2].parent_heading).to eq(doc.items[1])
  end

  it 'Does not Recognizes Markdown Table without separator' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '| Column A1 | Column B1 |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A1 | Column B3 |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # expect(doc.items.length).to eq 5
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(Paragraph)
    expect(doc.items[3]).to be_instance_of(Paragraph)
    expect(doc.items[4]).to be_instance_of(Paragraph)
    expect(doc.items[5]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].text).to eq '| Head Column A | Head Column B |'
    expect(doc.items[2].text).to eq '| Column A1 | Column B1 |'
    expect(doc.items[3].text).to eq '| Column A2 | Column B2 |'
    expect(doc.items[4].text).to eq '| Column A1 | Column B3 |'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Does not Recognizes Markdown Table without separator and odd number of lines' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '| Column A1 | Column B1 |'
    input_lines << '| Column A2 | Column B2 |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # expect(doc.items.length).to eq 4
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(Paragraph)
    expect(doc.items[3]).to be_instance_of(Paragraph)
    expect(doc.items[4]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].text).to eq '| Head Column A | Head Column B |'
    expect(doc.items[2].text).to eq '| Column A1 | Column B1 |'
    expect(doc.items[3].text).to eq '| Column A2 | Column B2 |'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Does not Recognizes Markdown Table if it is just a single line' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # expect(doc.items.length).to eq 1
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].text).to eq '| Head Column A | Head Column B |'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Recognizes Controlled Table out of any section' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '|---|---|'
    input_lines << '| Column A1 | >[SRS-001] |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A3 | Column B3 |'
    doc = Protocol.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(ControlledTable)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].column_names.length).to eq 2
    expect(doc.items[1].rows.length).to eq 3
    # expect(doc.items[0].rows[0].columns[0].text).to eq "FD"
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Recognizes Controlled Table within a section' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '|---|---|'
    input_lines << '| Column A1 | >[SRS-001] |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A1 | Column B3 |'
    doc = Protocol.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(ControlledTable)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[2].column_names.length).to eq 2
    expect(doc.items[2].rows.length).to eq 3
    # parent doc
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.items[2].parent_heading).to eq(doc.items[1])
  end

  it 'Does not Recognizes Controlled Table without separator' do
    input_lines = []
    input_lines << '| Head Column A | >[SRS-001] |'
    input_lines << '| Column A1 | >[SRS-001] |'
    input_lines << '| Column A2 | >[SRS-001] |'
    input_lines << '| Column A1 | >[SRS-001] |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # expect(doc.items.length).to eq 5
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(Paragraph)
    expect(doc.items[3]).to be_instance_of(Paragraph)
    expect(doc.items[4]).to be_instance_of(Paragraph)
    expect(doc.items[5]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].text).to eq '| Head Column A | >[SRS-001] |'
    expect(doc.items[2].text).to eq '| Column A1 | >[SRS-001] |'
    expect(doc.items[3].text).to eq '| Column A2 | >[SRS-001] |'
    expect(doc.items[4].text).to eq '| Column A1 | >[SRS-001] |'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Does not Recognizes Controlled Table without separator and odd number of lines' do
    input_lines = []
    input_lines << '| Head Column A | >[SRS-001] |'
    input_lines << '| Column A1 | >[SRS-001] |'
    input_lines << '| Column A2 | >[SRS-001] |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # expect(doc.items.length).to eq 4
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(Paragraph)
    expect(doc.items[3]).to be_instance_of(Paragraph)
    expect(doc.items[4]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].text).to eq '| Head Column A | >[SRS-001] |'
    expect(doc.items[2].text).to eq '| Column A1 | >[SRS-001] |'
    expect(doc.items[3].text).to eq '| Column A2 | >[SRS-001] |'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Does not Recognizes Controlled Table if it is just a single line' do
    input_lines = []
    input_lines << '| Head Column A | >[SRS-001] |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    # expect(doc.items.length).to eq 1
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].text).to eq '| Head Column A | >[SRS-001] |'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end

  it 'Does not Recognizes Controlled Table as a part of the Specification' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '|---|---|'
    input_lines << '| Column A1 | >[SRS-001] |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A1 | Column B3 |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[1]).to be_instance_of(MarkdownTable)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[1].column_names.length).to eq 2
    expect(doc.items[1].rows.length).to eq 3
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.items[1].parent_heading).to eq(doc.headings[0])
  end
  it 'Recognizes Controlled Table with multiple items covered in one test step' do
    input_lines = []
    input_lines << '# Heading Level 1'
    input_lines << '| Test Step | Test Step Description | Expected Output | Actual Output | Result | Req-ID |'
    input_lines << '|---|---|'
    input_lines << '| 1 | Description 1 | Expected Output 1 | Actual Output 1 |  | >[SRS-001], >[ARCH-002], >[SDD-003] |'
    input_lines << '| 2 | Description 2 | Expected Output 2 | Actual Output 2 |  | Column B2 |'
    input_lines << '| 3 | Description 3 | Expected Output 3 | Actual Output 3 |  | Column B3 |'
    doc = Protocol.new('C:/tp-001.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(ControlledTable)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Rows and Columns
    expect(doc.items[2].column_names.length).to eq 6
    expect(doc.items[2].rows.length).to eq 3
    expect(doc.items[2].rows[0].columns[0].row_id).to eq 'tp-001.1'
    expect(doc.items[2].rows[0].columns[1].text).to eq 'Description 1'
    expect(doc.items[2].rows[0].columns[2].text).to eq 'Expected Output 1'
    expect(doc.items[2].rows[0].columns[3].text).to eq 'Actual Output 1'
    expect(doc.items[2].rows[0].columns[4].text).to eq ''
    # References
    expect(doc.items[2].rows[0].columns[5].up_link_ids[0]).to eq 'SRS-001'
    expect(doc.items[2].rows[0].columns[5].up_link_ids[1]).to eq 'ARCH-002'
    expect(doc.items[2].rows[0].columns[5].up_link_ids[2]).to eq 'SDD-003'
    expect(doc.items[2].rows[0].columns[5].up_link_ids.length).to eq 3
    expect(doc.items[2].rows[0].columns[5].up_link_doc_ids).to have_key('srs')
    expect(doc.items[2].rows[0].columns[5].up_link_doc_ids).to have_key('arch')
    expect(doc.items[2].rows[0].columns[5].up_link_doc_ids).to have_key('sdd')
    expect(doc.items[2].rows[0].parent_doc.up_link_docs).to have_key('srs')
    expect(doc.items[2].rows[0].parent_doc.up_link_docs).to have_key('arch')
    expect(doc.items[2].rows[0].parent_doc.up_link_docs).to have_key('sdd')
    # parent doc
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.items[2].parent_heading).to eq(doc.items[1])
  end
  it 'Recognizes Heading2 and Paragraph' do
    input_lines = []
    input_lines << '## Heading Level 2'
    input_lines << 'This is a Paragraph Text'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 4
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Heading)
    expect(doc.items[2]).to be_instance_of(Paragraph)
    expect(doc.items[3]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[1].level).to eq 2
    expect(doc.items[1].text).to eq 'Heading Level 2'
    # paragraph
    expect(doc.items[2].text).to eq 'This is a Paragraph Text'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    expect(doc.items[2].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[1]).to eq(doc.items[1])
    expect(doc.items[2].parent_heading).to eq(doc.items[1])
  end
  it 'Recognizes Paragraph with no headings' do
    input_lines = []
    input_lines << 'This is a Paragraph Text'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Paragraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].text).to eq 'This is a Paragraph Text'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Controlled Paragraph with no headings' do
    input_lines = []
    input_lines << '[SRS-001] This is a Controlled Paragraph Text'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(ControlledParagraph)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].text).to eq 'This is a Controlled Paragraph Text'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Image with no headings' do
    input_lines = []
    input_lines << '![This is an Image](./img/001.png)'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Image)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].text).to eq 'This is an Image'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Unordered List with no headings' do
    input_lines = []
    input_lines << '* This is a list item'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(MarkdownList)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].rows[0]).to eq 'This is a list item'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Ordered List with no headings' do
    input_lines = []
    input_lines << '1. This is a list item'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(MarkdownList)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].rows[0]).to eq 'This is a list item'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Markdown Table with no headings' do
    input_lines = []
    input_lines << '| Head Column A | Head Column B |'
    input_lines << '|---|---|'
    input_lines << '| Column A1 | Column B1 |'
    input_lines << '| Column A2 | Column B2 |'
    input_lines << '| Column A1 | Column B3 |'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(MarkdownTable)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].column_names.length).to eq 2
    expect(doc.items[1].rows.length).to eq 3
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Blockquote with no headings' do
    input_lines = []
    input_lines << '>This is a note'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(Blockquote)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].text).to eq 'This is a note'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Code Block with no headings' do
    input_lines = []
    input_lines << '```Java'
    input_lines << 'public static void main()'
    input_lines << '```'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(CodeBlock)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].suggested_format).to eq 'Java'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes TODO block with no headings' do
    input_lines = []
    input_lines << 'TODO: Text'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 3
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.items[1]).to be_instance_of(TodoBlock)
    expect(doc.items[2]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # paragraph
    expect(doc.items[1].text).to eq '**TODO**:  Text'
    # parent doc
    expect(doc.items[1].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
    expect(doc.items[1].parent_heading).to eq(doc.items[0])
  end
  it 'Recognizes Frontmatter block with no headings' do
    input_lines = []
    input_lines << '---'
    input_lines << 'field: "value"'
    input_lines << '---'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 2
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.frontmatter).to be_instance_of(Frontmatter)
    expect(doc.items[1]).to be_instance_of(DocFooter)
    # Consider file name as a document title
    expect(doc.title).to eq 'srs.md'
    # If there is no Title, we always have a dummy heading with level 0
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'srs.md'
    # frontmatter
    expect(doc.frontmatter.parameters['field']).to eq 'value'
    # parent doc
    expect(doc.items[0].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
  end
  it 'Recognizes document title from the Frontmatter field' do
    input_lines = []
    input_lines << '---'
    input_lines << 'title: "This is a Document Title"'
    input_lines << '---'
    doc = Specification.new('C:/srs.md')

    DocParser.parse(doc, input_lines)

    expect(doc.items.length).to eq 2
    expect(doc.items[0]).to be_instance_of(Heading)
    expect(doc.frontmatter).to be_instance_of(Frontmatter)
    expect(doc.items[1]).to be_instance_of(DocFooter)
    # Title is extracted from Frontmatter
    expect(doc.title).to eq 'This is a Document Title'
    expect(doc.items[0].level).to eq 0
    expect(doc.items[0].text).to eq 'This is a Document Title'
    # frontmatter
    expect(doc.frontmatter.parameters['title']).to eq 'This is a Document Title'
    # parent doc
    expect(doc.items[0].parent_doc).to eq(doc)
    # headings
    expect(doc.headings[0]).to eq(doc.items[0])
  end
end
