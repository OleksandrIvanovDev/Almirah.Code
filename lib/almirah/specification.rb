require_relative "doc_items/doc_item"
require_relative "doc_items/heading"
require_relative "doc_items/paragraph"
require_relative "doc_items/controlled_paragraph"

class Specification

    attr_accessor :path
    attr_accessor :docItems
    attr_accessor :title
    attr_accessor :key

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @docItems = Array.new

        @key = File.basename(fele_path, File.extname(fele_path)).upcase

        self.parse()
    end

    def parse()

        file = File.open( self.path )
        file_lines = file.readlines     
        file.close

        file_lines.each do |s|
            if s.lstrip != ""
                if res = /^([#]{1,})\s(.*)/.match(s)                
                    level = res[1].length
                    value = res[2]
                    item = Heading.new(value, level)
                    self.docItems.append(item)
                    
                    if level == 1
                        self.title = value
                    end    
                                    
                else # reqular paragraph
                    item = Paragraph.new(s)
                    self.docItems.append(item)
                end
            end
        end
    end
end