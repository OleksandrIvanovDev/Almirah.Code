require_relative "doc_items/doc_item"
require_relative "doc_items/heading"
require_relative "doc_items/paragraph"
require_relative "doc_items/blockquote"
require_relative "doc_items/controlled_paragraph"
require_relative "doc_items/markdown_table"
require_relative "doc_items/controlled_table"
require_relative "doc_items/image"
require_relative "doc_items/markdown_list"

class Specification

    attr_accessor :path
    attr_accessor :docItems
    attr_accessor :headings
    attr_accessor :title
    attr_accessor :key
    attr_accessor :up_link_key
    attr_accessor :dictionary
    attr_accessor :controlledParagraphs
    attr_accessor :tempMdTable
    attr_accessor :tempMdList

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @docItems = Array.new
        @headings = Array.new
        @controlledParagraphs = Array.new
        @dictionary = Hash.new
        @tempMdTable = nil
        @tempMdList = nil

        @key = File.basename(fele_path, File.extname(fele_path)).upcase
        @up_link_key = ""

        self.parse()
    end

    def parse()

        file = File.open( self.path )
        file_lines = file.readlines     
        file.close

        file_lines.each do |s|
            if s.lstrip != ""
                if res = /^([#]{1,})\s(.*)/.match(s)     # Heading    
                    
                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end
                    if @tempMdList
                        self.docItems.append(@tempMdList)
                        @tempMdList = nil
                    end 

                    level = res[1].length
                    value = res[2]
                    item = Heading.new(value, level)
                    self.docItems.append(item)
                    self.headings.append(item)

                    if level == 1 && self.title == ""
                        self.title = value
                    end   
                     
                elsif res = /^\[(\S*)\]\s+(.*)/.match(s)     # Controlled Paragraph

                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end
                    if @tempMdList
                        self.docItems.append(@tempMdList)
                        @tempMdList = nil
                    end 

                    id = res[1]
                    text = res[2]

                    #check if it contains the uplink
                    if tmp = /(.*)\s+>\[(\S*)\]$/.match(text)

                        text = tmp[1]
                        up_link = tmp[2]
                        
                        if tmp = /^([a-zA-Z]+)[-]\d+/.match(up_link)
                            self.up_link_key = tmp[1]
                        end
                    end

                    item = ControlledParagraph.new( text, id )
                    item.up_link = up_link

                    self.docItems.append(item)
                    self.dictionary[ id.to_s ] = item           #for fast search
                    self.controlledParagraphs.append(item)      #for fast search

                elsif res = /^[!]\[(.*)\]\((.*)\)/.match(s)     # Image

                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end
                    if @tempMdList
                        self.docItems.append(@tempMdList)
                        @tempMdList = nil
                    end

                    img_text = res[1]
                    img_path = res[2]

                    item = Image.new( img_text, img_path )

                    self.docItems.append(item)

                elsif res = /^(\*\s?)+(.*)/.match(s)   #check if bullet list
                    
                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end

                    row = res[2]

                    if @tempMdList
                        @tempMdList.addRow(row)
                    else
                        item = MarkdownList.new(row)
                        @tempMdList = item
                    end

                elsif s[0] == '|'   #check if table

                    if @tempMdList
                        self.docItems.append(@tempMdList)
                        @tempMdList = nil
                    end

                    if res = /^[|](-{3,})[|]/.match(s) #check if it is a separator first

                        if @tempMdTable 
                            #separator is found after heading - just skip it
                        else
                            #separator out of table scope consider it just as a regular paragraph
                            item = Paragraph.new(s)
                            self.docItems.append(item)
                        end

                    elsif res = /^[|](.*[|])/.match(s) #check if it looks as a table

                        row = res[1]

                        if @tempMdTable
                            # check if it is a controlled table
                            unless @tempMdTable.addRow(row)
                                @tempMdTable = ControlledTable.new(@tempMdTable)
                                @tempMdTable.addRow(row)
                            end
                        else
                            #start table from heading
                            @tempMdTable = MarkdownTable.new(row)
                        end
                    end

                elsif res = /^[>](.*)/.match(s)   #check if blockquote

                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end
                    if @tempMdList
                        self.docItems.append(@tempMdList)
                        @tempMdList = nil
                    end 

                    item = Blockquote.new(res[1])
                    self.docItems.append(item)

                else # Reqular Paragraph
                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end
                    if @tempMdList
                        self.docItems.append(@tempMdList)
                        @tempMdList = nil
                    end

                    item = Paragraph.new(s)
                    self.docItems.append(item)
                end
            end
        end
        # Finalize non-closed elements
        if @tempMdTable
            self.docItems.append(@tempMdTable)
            @tempMdTable = nil
        end
        if @tempMdList
            self.docItems.append(@tempMdList)
            @tempMdList = nil
        end
    end
end