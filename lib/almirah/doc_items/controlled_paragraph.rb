require_relative "paragraph"

class ControlledParagraph < Paragraph

    attr_accessor :id

    def initialize(text, id)
        @text = text
        @id = id
    end

    def to_html
        s = ''
        unless @@htmlTableRenderInProgress                    
            s += "<table>\n\r"
            s += "\t<thead> <th>#</th> <th>Text</th> <th>UL</th> <th>DL</th> <th>COV</th> </thead>\n\r"
            @@htmlTableRenderInProgress = true
        end
        s += "\t<tr>\n\r"
        s += "\t\t<td> <a name=\"#{@id}\"></a>#{@id} </td>\n\r"
        s += "\t\t<td>#{@text}</td>\n\r"
        s += "\t\t<td></td>\n\r"    # UL
        s += "\t\t<td></td>\n\r"    # DL
        s += "\t\t<td></td>\n\r"    # COV
        s += "\t</tr>\n\r"
        return s
    end 

end