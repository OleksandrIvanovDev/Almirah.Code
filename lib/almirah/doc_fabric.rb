#
require_relative "doc_types/base_document"
require_relative "doc_types/specification"
require_relative "doc_types/protocol"
#
require_relative "doc_items/text_line"
require_relative "doc_items/doc_item"
require_relative "doc_items/heading"
require_relative "doc_items/paragraph"
require_relative "doc_items/blockquote"
require_relative "doc_items/todo_block"
require_relative "doc_items/controlled_paragraph"
require_relative "doc_items/markdown_table"
require_relative "doc_items/controlled_table"
require_relative "doc_items/image"
require_relative "doc_items/markdown_list"

class DocFabric

    def self.add_lazy_doc_id(path)
        if res = /(\w+)[.]md$/.match(path)
            TextLine.add_lazy_doc_id(res[1])
        end
    end

    def self.create_specification(path)
        doc = Specification.new path
        DocFabric.parse_document doc
        return doc
    end

    def self.create_protocol(path)
        doc = Protocol.new path
        DocFabric.parse_document doc
        return doc
    end

    def self.parse_document(doc)

        tempMdTable = nil
        tempMdList = nil

        file = File.open( doc.path )
        file_lines = file.readlines     
        file.close

        file_lines.each do |s|
            if s.lstrip != ""
                if res = /^([#]{1,})\s(.*)/.match(s)     # Heading    
                    
                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if  tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end 

                    level = res[1].length
                    value = res[2]

                    if level == 1 && doc.title == ""
                        doc.title = value
                        Heading.reset_global_section_number()
                    end 

                    item = Heading.new(value, level)
                    item.parent_doc = doc
                    doc.items.append(item)
                    doc.headings.append(item)
  
                elsif res = /^\%\s(.*)/.match(s)     # Pandoc Document Title

                    title = res[1]

                    if doc.title == ""
                        doc.title = title
                        Heading.reset_global_section_number()
                    end 

                    item = Heading.new(title, 1)
                    item.parent_doc = doc
                    doc.items.append(item)
                    doc.headings.append(item)

                    Heading.reset_global_section_number()   # Pandoc Document Title is not a section, so it shall not be taken into account in numbering
                    
                elsif res = /^\[(\S*)\]\s+(.*)/.match(s)     # Controlled Paragraph

                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end 

                    id = res[1]
                    text = res[2]
                    up_links = nil

                    #check if it contains the uplink (one or many)
                    #TODO: check this regular expression
                    first_pos = text.length # for trailing commas
                    tmp =  text.scan( /(>\[(?>[^\[\]]|\g<0>)*\])/ )           # >[SRS-001], >[SYS-002]
                    if tmp.length >0
                        up_links = Array.new
                        tmp.each do |ul|
                            up_links.append(ul[0])
                            # try to find the real end of text
                            pos = text.index(ul[0])
                            if pos < first_pos
                                first_pos = pos
                            end
                            # remove uplink from text
                            text = text.split(ul[0]).join("")
                        end
                        # remove trailing commas and spaces
                        if text.length > first_pos
                            first_pos -= 1
                            text = text[0..first_pos].strip
                        end
                    end

                    # since we already know id and text 
                    item = ControlledParagraph.new( text, id )

                    if up_links
                        up_links.each do |ul|
                            if tmp = />\[(\S*)\]$/.match(ul)                    # >[SRS-001]
                                up_link_id = tmp[1]

                                unless item.up_link_ids
                                    item.up_link_ids = Array.new
                                end

                                item.up_link_ids.append(up_link_id)      
                                doc.items_with_uplinks_number += 1     #for statistics
                                    
                                if tmp = /^([a-zA-Z]+)[-]\d+/.match(up_link_id) # SRS
                                    doc.up_link_doc_id[ tmp[1].downcase.to_s ] = tmp[1].downcase       # multiple documents could be up-linked                            
                                end
                            end
                        end
                    end

                    
                    item.parent_doc = doc
                    item.parent_heading = doc.headings[-1]

                    doc.items.append(item)
                    #for statistics
                    if doc.dictionary.has_key?( id.to_s )
                        doc.duplicated_ids_number += 1
                        doc.duplicates_list.append(item)
                    else
                        doc.dictionary[ id.to_s ] = item       #for fast search
                    end
                    doc.controlled_items.append(item)      #for fast search

                    #for statistics
                    n = /\d+/.match(id)[0].to_i
                    if n > doc.last_used_id_number
                        doc.last_used_id = id
                        doc.last_used_id_number = n
                    end

                elsif res = /^[!]\[(.*)\]\((.*)\)/.match(s)     # Image

                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end

                    img_text = res[1]
                    img_path = res[2]

                    item = Image.new( img_text, img_path )
                    item.parent_doc = doc

                    doc.items.append(item)

                elsif res = /^(\*\s?)(.*)/.match(s)   #check if unordered list start
                    
                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end

                    row = res[2]

                    if tempMdList
                        tempMdList.addRow(s)
                    else
                        item = MarkdownList.new(false)
                        item.addRow(s)
                        item.parent_doc = doc
                        tempMdList = item
                    end

                elsif res = /^\d[.]\s(.*)/.match(s)   #check if ordered list start
                    
                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end

                    row = res[1]

                    if tempMdList
                        tempMdList.addRow(s)
                    else
                        item = MarkdownList.new(true)
                        item.addRow(s)
                        item.parent_doc = doc
                        tempMdList = item
                    end

                elsif s[0] == '|'   #check if table

                    if tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end

                    if res = /^[|](-{3,})[|]/.match(s) #check if it is a separator first

                        if tempMdTable 
                            #separator is found after heading - just skip it
                        else
                            #separator out of table scope consider it just as a regular paragraph
                            item = Paragraph.new(s)
                            item.parent_doc = doc
                            doc.items.append(item)
                        end

                    elsif res = /^[|](.*[|])/.match(s) #check if it looks as a table

                        row = res[1]

                        if tempMdTable
                            # check if it is a controlled table
                            unless tempMdTable.addRow(row)
                                tempMdTable = ControlledTable.new(tempMdTable, doc)
                                tempMdTable.parent_doc = doc
                                tempMdTable.addRow(row)
                            end
                        else
                            #start table from heading
                            tempMdTable = MarkdownTable.new(row)
                            tempMdTable.parent_doc = doc
                        end
                    end

                elsif res = /^[>](.*)/.match(s)   #check if blockquote

                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end 

                    item = Blockquote.new(res[1])
                    item.parent_doc = doc
                    doc.items.append(item)
                
                elsif res = /^TODO\:(.*)/.match(s)   #check if TODO block

                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end 

                    text = "**TODO**: " + res[1]

                    item = TodoBlock.new(text)
                    item.parent_doc = doc
                    doc.items.append(item)
                    doc.todo_blocks.append(item)

                else # Reqular Paragraph
                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if tempMdList
                        if MarkdownList.unordered_list_item?(s) || MarkdownList.ordered_list_item?(s)
                            tempMdList.addRow(s)
                            next
                        else
                            doc.items.append tempMdList
                            tempMdList = nil
                        end
                    end

                    item = Paragraph.new(s)
                    item.parent_doc = doc
                    doc.items.append(item)
                end
            else
                if tempMdList   # lists are separated by emty line from each other
                    doc.items.append tempMdList
                    tempMdList = nil
                end
            end
        end
        # Finalize non-closed elements
        if tempMdTable
            doc.items.append tempMdTable
            tempMdTable = nil
        end
        if tempMdList
            doc.items.append tempMdList
            tempMdList = nil
        end
    end
end