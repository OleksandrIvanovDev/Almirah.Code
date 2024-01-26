require_relative "paragraph"

class ControlledParagraph < Paragraph

    attr_accessor :id
    attr_accessor :up_link
    attr_accessor :down_links

    def initialize(text, id)
        @text = text
        @id = id
        @up_link = nil
        @down_links = nil
    end

    def to_html
        s = ''
        unless @@htmlTableRenderInProgress                    
            s += "<table class=\"controlled\">\n\r"
            s += "\t<thead> <th>#</th> <th>Text</th> <th>UL</th> <th>DL</th> <th>COV</th> </thead>\n\r"
            @@htmlTableRenderInProgress = true
        end
        s += "\t<tr>\n\r"
        s += "\t\t<td class=\"item_id\"> <a name=\"#{@id}\"></a>#{@id} </td>\n\r"
        s += "\t\t<td class=\"item_text\">#{@text}</td>\n\r"

        if @up_link
            if tmp = /^([a-zA-Z]+)[-]\d+/.match(@up_link)
                up_link_doc_name = tmp[1].downcase
            end
            s += "\t\t<td class=\"item_id\"><a href=\"./../#{up_link_doc_name}/#{up_link_doc_name}.html\" class=\"external\">#{@up_link}</a></td>\n\r"
        else
            s += "\t\t<td class=\"item_id\"></td>\n\r"
        end

        if @down_links
            if tmp = /^([a-zA-Z]+)[-]\d+/.match(@down_links[0].id)    # guessing that all the links refer to one document
                down_link_doc_name = tmp[1].downcase
            end
            s += "\t\t<td class=\"item_id\"><a href=\"./../#{down_link_doc_name}/#{down_link_doc_name}.html\" class=\"external\">#{@down_links.length}</a></td>\n\r"
        else
            s += "\t\t<td class=\"item_id\"></td>\n\r"
        end

        #s += "\t\t<td></td>\n\r"    # UL
        #s += "\t\t<td></td>\n\r"    # DL
        s += "\t\t<td class=\"item_id\"></td>\n\r"    # COV
        s += "\t</tr>\n\r"
        return s
    end 

end