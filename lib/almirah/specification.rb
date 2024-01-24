require_relative "doc_items/doc_item"
require_relative "doc_items/heading"
require_relative "doc_items/paragraph"
require_relative "doc_items/controlled_paragraph"
require_relative "doc_items/markdown_table"

class Specification

    attr_accessor :path
    attr_accessor :docItems
    attr_accessor :title
    attr_accessor :key
    attr_accessor :upLinkKey
    attr_accessor :dictionary
    attr_accessor :controlledParagraphs
    attr_accessor :tempMdTable

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @docItems = Array.new
        @controlledParagraphs = Array.new
        @dictionary = Hash.new
        @tempMdTable = nil

        @key = File.basename(fele_path, File.extname(fele_path)).upcase
        @upLinkKey = ""

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

                    level = res[1].length
                    value = res[2]
                    item = Heading.new(value, level)
                    self.docItems.append(item)
                    
                    if level == 1
                        self.title = value
                    end   
                     
                elsif res = /^\[(\S*)\]\s+(.*)/.match(s)     # Controlled Paragraph

                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end 

                    id = res[1]
                    text = res[2]
                    #check if it contains the uplink
                    tmp = /(.*)\s+>\[(\S*)\]$/.match(text)

                    if tmp
                        text = tmp[1]
                        uplink = tmp[2]

                        item = ControlledParagraph.new( tmp, id )

                        if tmp = /^([a-zA-Z]+)[-]\d+/.match(uplink)
                            self.upLinkKey = tmp[1]
                        end
                    else
                        item = ControlledParagraph.new( text, id )
                    end

                    self.docItems.append(item)
                    self.dictionary[ id.to_s ] = item           #for fast search
                    self.controlledParagraphs.append(item)      #for fast search

                elsif s[0] == '|'   #check if table

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
                            @tempMdTable.addRow(row)
                        else
                            #start table from heading
                            @tempMdTable = MarkdownTable.new(row)
                        end
                    end

                else # Reqular Paragraph
                    if @tempMdTable
                        self.docItems.append(@tempMdTable)
                        @tempMdTable = nil
                    end 
                    item = Paragraph.new(s)
                    self.docItems.append(item)
                end
            end
        end
    end
end