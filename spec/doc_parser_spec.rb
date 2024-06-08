describe 'DocParser' do
    it 'Recognizes Heading1' do
      input_lines = []
      input_lines << "# Heading Level 1"
      doc = Specification.new("C:/srs.md")
      
      DocParser.parse(doc, input_lines)

      expect(doc.items.length).to eq 2
      expect(doc.items[0]).to be_instance_of(Heading)
      expect(doc.items[1]).to be_instance_of(DocFooter)
      # Consider first heading as a document title
      expect(doc.title).to eq "Heading Level 1"
      # But only pandoc title formal is level 0 section (not numbered)
      expect(doc.items[0].level).to eq 1 
      expect(doc.items[0].text).to eq "Heading Level 1"
      # parent doc
      expect(doc.items[0].parent_doc).to eq(doc)
      # headings
      expect(doc.headings[0]).to eq(doc.items[0])
      # section number
      expect(doc.headings[0].section_number).to eq "1"
    end

    it 'Recognizes pandoc document title' do
        input_lines = []
        input_lines << "% Heading Level 0"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Consider first heading as a document title
        expect(doc.title).to eq "Heading Level 0"
        # But only pandoc title formal is level 0 section (not numbered)
        expect(doc.items[0].level).to eq 0 
        expect(doc.items[0].text).to eq "Heading Level 0"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        # headings
        expect(doc.headings[0]).to eq(doc.items[0])
      end

      it 'Recognizes Heading2' do
        input_lines = []
        input_lines << "## Heading Level 2"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Consider first heading as a document title
        expect(doc.title).to eq ""
        # But only pandoc title formal is level 0 section (not numbered)
        expect(doc.items[0].level).to eq 2 
        expect(doc.items[0].text).to eq "Heading Level 2"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        # headings
        expect(doc.headings[0]).to eq(doc.items[0])
      end
     
      it 'Recognizes Heading1 and Heading2' do
        input_lines = []
        input_lines << "# Heading Level 1"
        input_lines << "## Heading Level 2"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 3
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(Heading)
        expect(doc.items[2]).to be_instance_of(DocFooter)
        # Consider first heading as a document title
        expect(doc.title).to eq "Heading Level 1"
        # But only pandoc title formal is level 0 section (not numbered)
        expect(doc.items[0].level).to eq 1 
        expect(doc.items[0].text).to eq "Heading Level 1"
        expect(doc.items[1].level).to eq 2 
        expect(doc.items[1].text).to eq "Heading Level 2"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        expect(doc.items[1].parent_doc).to eq(doc)
        # headings
        expect(doc.headings[0]).to eq(doc.items[0])
        expect(doc.headings[1]).to eq(doc.items[1])
        expect(doc.headings.length).to eq 2
      end

      it 'Recognizes Heading1 and Heading1' do
        input_lines = []
        input_lines << "# Heading Level 1 - 1"
        input_lines << "# Heading Level 1 - 2"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 3
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(Heading)
        expect(doc.items[2]).to be_instance_of(DocFooter)
        # Consider first heading as a document title
        expect(doc.title).to eq "Heading Level 1 - 1"
        # But only pandoc title formal is level 0 section (not numbered)
        expect(doc.items[0].level).to eq 1 
        expect(doc.items[0].text).to eq "Heading Level 1 - 1"
        expect(doc.items[1].level).to eq 1 
        expect(doc.items[1].text).to eq "Heading Level 1 - 2"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        expect(doc.items[1].parent_doc).to eq(doc)
        # headings
        expect(doc.headings[0]).to eq(doc.items[0])
        expect(doc.headings[1]).to eq(doc.items[1])
        expect(doc.headings.length).to eq 2
      end

      it 'Recognizes Heading1 as a document title for two documents but with correct section number' do
        input_lines = []
        input_lines << "# Heading Level 1"
        doc = Specification.new("C:/srs.md")
        doc2 = Specification.new("C:/arch.md")
        
        DocParser.parse(doc, input_lines)
        DocParser.parse(doc2, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(DocFooter)

        expect(doc2.items.length).to eq 2
        expect(doc2.items[0]).to be_instance_of(Heading)
        expect(doc2.items[1]).to be_instance_of(DocFooter)
        # Consider first heading as a document title
        expect(doc.title).to eq "Heading Level 1"
        expect(doc2.title).to eq "Heading Level 1"
        # But only pandoc title formal is level 0 section (not numbered)
        expect(doc.items[0].level).to eq 1 
        expect(doc.items[0].text).to eq "Heading Level 1"
        expect(doc2.items[0].level).to eq 1 
        expect(doc2.items[0].text).to eq "Heading Level 1"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        expect(doc2.items[0].parent_doc).to eq(doc2)
        # headings
        expect(doc.headings[0]).to eq(doc.items[0])
        expect(doc2.headings[0]).to eq(doc2.items[0])
        # section number
        expect(doc.headings[0].section_number).to eq "1"
        expect(doc2.headings[0].section_number).to eq "1"
      end

      it 'Recognizes Controlled Paragraph out of any section' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph"
        expect(doc.items[0].id).to eq "SRS-001"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        # headings
        expect(doc.items[0].parent_heading).to eq(nil)
      end

      it 'Recognizes Controlled Paragraph with id in lower case as well' do
        input_lines = []
        input_lines << "[srs-001] This is a Controlled Paragraph"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph"
        expect(doc.items[0].id).to eq "SRS-001"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        # headings
        expect(doc.items[0].parent_heading).to eq(nil)
      end

      it 'Recognizes Controlled Paragraph within a section' do
        input_lines = []
        input_lines << "# Heading Level 1"
        input_lines << "[SRS-001] This is a Controlled Paragraph"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 3
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(ControlledParagraph)
        expect(doc.items[2]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[1].text).to eq "This is a Controlled Paragraph"
        expect(doc.items[1].id).to eq "SRS-001"
        # parent doc
        expect(doc.items[1].parent_doc).to eq(doc)
        # headings
        expect(doc.items[1].parent_heading).to eq(doc.items[0])
      end

      it 'Recognizes Controlled Paragraph with up-link' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with up-link >[SYS-002]"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph with up-link"
        expect(doc.items[0].id).to eq "SRS-001"
        # up-link
        expect(doc.items[0].up_link_ids[0]).to eq "SYS-002"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        # headings
        expect(doc.items[0].parent_heading).to eq(nil)
      end
      it 'Recognizes Controlled Paragraph with up-link even in lower case' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with up-link >[sys-002]"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph with up-link"
        expect(doc.items[0].id).to eq "SRS-001"
        # up-link
        expect(doc.items[0].up_link_ids[0]).to eq "SYS-002"
        # parent doc
        expect(doc.items[0].parent_doc).to eq(doc)
        # headings
        expect(doc.items[0].parent_heading).to eq(nil)
        # references
        expect(doc.dictionary).to have_key("SRS-001")
        expect(doc.controlled_items[0]).to eq(doc.items[0])
        expect(doc.last_used_id).to eq("SRS-001")
        expect(doc.items_with_uplinks_number).to eq 1
      end
      it 'Recognizes Controlled Paragraph and maintains all required refereces' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with up-link >[SYS-002]"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)

        # references
        expect(doc.dictionary).to have_key("SRS-001")
        expect(doc.controlled_items[0]).to eq(doc.items[0])
        expect(doc.last_used_id).to eq("SRS-001")
        expect(doc.items_with_uplinks_number).to eq 1
        expect(doc.duplicated_ids_number).to eq 0
        # document ids are always in lower case
        expect(doc.id).to eq("srs")
        expect(doc.up_link_doc_id).to have_key("sys")
      end
      it 'Recognizes Controlled Paragraph with duplicated ids' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with up-link >[SYS-002]"
        input_lines << "[srs-001] This is a duplicated Controlled Paragraph"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)

        expect(doc.items.length).to eq 3
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(ControlledParagraph)
        expect(doc.items[2]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph with up-link"
        expect(doc.items[0].id).to eq "SRS-001"
        expect(doc.items[1].text).to eq "This is a duplicated Controlled Paragraph"
        expect(doc.items[1].id).to eq "SRS-001"
        # references
        expect(doc.dictionary).to have_key("SRS-001")
        expect(doc.controlled_items[0]).to eq(doc.items[0])
        expect(doc.controlled_items[1]).to eq(doc.items[1])
        expect(doc.last_used_id).to eq("SRS-001")
        expect(doc.items_with_uplinks_number).to eq 1
        expect(doc.duplicated_ids_number).to eq 1
        # document ids are always in lower case
        expect(doc.id).to eq("srs")
        expect(doc.up_link_doc_id).to have_key("sys")
      end
      it 'Recognizes Controlled Paragraph with two up-links' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with two up-links >[SYS-002], >[SYS-003]"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph with two up-links"
        expect(doc.items[0].id).to eq "SRS-001"
        # up-link
        expect(doc.items[0].up_link_ids[0]).to eq "SYS-002"
        expect(doc.items[0].up_link_ids[1]).to eq "SYS-003"
        # reference
        expect(doc.up_link_doc_id).to have_key("sys")
      end
      it 'Recognizes Controlled Paragraph with two same up-links' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with two same up-links >[SYS-002], >[SYS-002]"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph with two same up-links"
        expect(doc.items[0].id).to eq "SRS-001"
        # up-link
        expect(doc.items[0].up_link_ids[0]).to eq "SYS-002"
        expect(doc.items[0].up_link_ids.length).to eq 1
        # reference
        expect(doc.up_link_doc_id).to have_key("sys")
      end
      it 'Recognizes Controlled Paragraph with recursive up-links' do
        input_lines = []
        input_lines << "[SRS-001] This is a Controlled Paragraph with recursive up-links >[SRS-001], >[SYS-002]"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(ControlledParagraph)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Text and id (id is in uppercase)
        expect(doc.items[0].text).to eq "This is a Controlled Paragraph with recursive up-links"
        expect(doc.items[0].id).to eq "SRS-001"
        # up-link
        expect(doc.items[0].up_link_ids[0]).to eq "SYS-002"
        expect(doc.items[0].up_link_ids.length).to eq 1
        # reference
        expect(doc.up_link_doc_id).to have_key("sys")
        expect(doc.up_link_doc_id.size).to eq 1
      end
end