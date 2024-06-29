require_relative "doc_item"

class ControlledTableRow < DocItem

    attr_accessor :id
    attr_accessor :up_link_ids
    attr_accessor :columns
    
    def initialize
        @id = ""
        @up_link_ids = nil
        @columns = []
    end

    def to_html
        s = ""
        s += "\t<tr>\n"
        @columns.each do |col|
            s += col.to_html    # "\t\t<td>#{col}</td>\n\r"
        end
        s += "\t</tr>\n"
    end
end