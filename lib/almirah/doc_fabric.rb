#
require_relative "doc_types/base_document"
require_relative "doc_types/specification"
require_relative "doc_types/protocol"
#
require_relative "doc_items/doc_item"
require_relative "doc_items/heading"
require_relative "doc_items/paragraph"
require_relative "doc_items/blockquote"
require_relative "doc_items/controlled_paragraph"
require_relative "doc_items/markdown_table"
require_relative "doc_items/controlled_table"
require_relative "doc_items/image"
require_relative "doc_items/markdown_list"

class DocFabric

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
                    item = Heading.new(value, level)
                    item.parent_doc = doc
                    doc.items.append(item)
                    doc.headings.append(item)

                    if level == 1 && doc.title == ""
                        doc.title = value
                    end   
                        
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

                    #check if it contains the uplink
                    if tmp = /(.*)\s+>\[(\S*)\]$/.match(text)           # >[SRS-001]

                        text = tmp[1]
                        up_link = tmp[2]
                        
                        if tmp = /^([a-zA-Z]+)[-]\d+/.match(up_link)    # SRS
                            doc.up_link_doc_id = tmp[1].downcase
                        end
                    end

                    item = ControlledParagraph.new( text, id )
                    item.parent_doc = doc
                    if up_link
                         item.up_link = up_link
                         doc.items_with_uplinks_number += 1     #for statistics
                    end

                    doc.items.append(item)
                    doc.dictionary[ id.to_s ] = item       #for fast search
                    doc.controlled_items.append(item)      #for fast search

                    #for statistics
                    n = /\d+/.match(id)[0].to_i
                    if n == doc.last_used_id_number
                        doc.duplicated_ids_number += 1
                    elsif n > doc.last_used_id_number
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

                elsif res = /^(\*\s?)+(.*)/.match(s)   #check if bullet list
                    
                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end

                    row = res[2]

                    if tempMdList
                        tempMdList.addRow(row)
                    else
                        item = MarkdownList.new(row)
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

                else # Reqular Paragraph
                    if tempMdTable
                        doc.items.append tempMdTable
                        tempMdTable = nil
                    end
                    if tempMdList
                        doc.items.append tempMdList
                        tempMdList = nil
                    end

                    item = Paragraph.new(s)
                    item.parent_doc = doc
                    doc.items.append(item)
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