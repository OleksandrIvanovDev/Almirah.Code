require_relative "doc_item"


class ControlledTableColumn

    attr_accessor :text
    
    def initialize(text)
        @text = text
    end

    def to_html
        "\t\t<td>#{@text}</td>\n\r"
    end
end


class RegualrColumn < ControlledTableColumn

end


class TestStepNumberColumn < ControlledTableColumn

    attr_accessor :step_number
    
    def initialize(text)
        @step_number = text.to_i
        @text =  text
    end

    def to_html
        "\t\t<td style='text-align: center;'>#{@text}</td>\n\r"
    end
end 


class TestStepResultColumn <  ControlledTableColumn

end


class TestStepReferenceColumn <  ControlledTableColumn

    attr_accessor :up_link
    attr_accessor :up_link_key

    def initialize(text)
        
        @up_link = nil
        @up_link_doc_id = nil

        if tmp = />\[(\S*)\]/.match(text)   # >[SRS-001]
            @up_link = tmp[1]
            if tmp = /^([a-zA-Z]+)[-]\d+/.match(@up_link)   # SRS
                @up_link_doc_id = tmp[1].downcase 
            end
        end
    end

    def to_html
        if @up_link
            "\t\t<td class=\"item_id\"><a href=\"./../#{@up_link_doc_id}/#{@up_link_doc_id}.html\" class=\"external\">#{@up_link}</a></td>\n\r"
        else
            "\t\t<td style='text-align: center;'></td>\n\r"
        end
    end
    
end


class ControlledTable < DocItem

    attr_accessor :column_names
    attr_accessor :rows
    attr_accessor :up_link_key

    def initialize(markdown_table)
        @up_link_key = nil
        @column_names = markdown_table.column_names
        # copy and re-format existing rows
        @rows = Array.new

        markdown_table.rows.each do |r|
            @rows.append(format_columns(r))
        end   
    end

    def addRow(row)

        columns = row.split('|')

        @rows.append(format_columns(columns))

        return true
    end

    def format_columns(columns)

        new_row = Array.new

        columns.each_with_index do | element, index |

            if index == 0 # it is expected that test step id is placed in the first columl
                
                col = TestStepNumberColumn.new element
                new_row.append col

            elsif index + 1 == columns.length # it is expected that a link is placed to the last column only
                
                col = TestStepReferenceColumn.new element
                new_row.append col
                # save uplink key 
                if col.up_link_key != nil && @up_link_key != nil
                    @up_link_key = col.up_link_key
                end

            elsif index + 2 == columns.length # it is expected that test step result is placed to the pre-last column only
                
                col = TestStepResultColumn.new element
                new_row.append col

            else
                col = RegualrColumn.new element
                new_row.append col
            end             
        end
        return new_row
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end
                   
        s += "<table class=\"markdown_table\">\n"
        s += "\t<thead>" 

        @column_names.each do |h|
            s += " <th>#{h}</th>"
        end

        s += " </thead>\n"

        @rows.each do |row|
            s += "\t<tr>\n"
            row.each do |col|
                s += col.to_html    # "\t\t<td>#{col}</td>\n\r"
            end
            s += "\t</tr>\n"
        end

        s += "</table>\n"

        return s
    end

end