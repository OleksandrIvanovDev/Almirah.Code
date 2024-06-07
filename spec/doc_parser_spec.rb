describe 'DocParser' do
    it 'Recognizes Heading1' do
      input_lines = []
      input_lines << "# Heading Level 1"
      doc = Specification.new("C:/srs.md")
      
      DocParser.parse(doc, input_lines)

      expect(doc.items.length).to eq 2
      expect(doc.items[0]).to be_instance_of(Heading)
      expect(doc.items[1]).to be_instance_of(DocFooter)
      # Consider first heading as a document title and document root with level 0
      expect(doc.title).to eq "Heading Level 1"
      expect(doc.items[0].level).to eq 0 
      expect(doc.items[0].text).to eq "Heading Level 1"
      # parent doc
      expect(doc.items[0].parent_doc).to eq(doc)
      # headings
      expect(doc.headings[0]).to eq(doc.items[0])
    end

    it 'Recognizes pandoc document title' do
        input_lines = []
        input_lines << "% Heading Level 1"
        doc = Specification.new("C:/srs.md")
        
        DocParser.parse(doc, input_lines)
  
        expect(doc.items.length).to eq 2
        expect(doc.items[0]).to be_instance_of(Heading)
        expect(doc.items[1]).to be_instance_of(DocFooter)
        # Consider first heading as a document title and document root with level 0
        expect(doc.title).to eq "Heading Level 1"
        expect(doc.items[0].level).to eq 0 
        expect(doc.items[0].text).to eq "Heading Level 1"
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
        # Consider first heading as a document title and document root with level 0
        expect(doc.title).to eq ""
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
        # Consider first heading as a document title and document root with level 0
        expect(doc.title).to eq "Heading Level 1"
        expect(doc.items[0].level).to eq 0 
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
        # Consider first heading as a document title and document root with level 0
        expect(doc.title).to eq "Heading Level 1 - 1"
        expect(doc.items[0].level).to eq 0 
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
end