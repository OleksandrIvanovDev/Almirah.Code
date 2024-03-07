require_relative "doc_item"

class MarkdownList < DocItem

    attr_accessor :rows
    attr_accessor :text
    attr_accessor :is_ordered
    attr_accessor :indent_position
    attr_accessor :current_nesting_level

    @@lists_stack = Array.new

    def initialize(is_ordered)
        @rows = Array.new
        @is_ordered = is_ordered
        @current_nesting_level = 0
        @indent_position = 0
        @text = ''

        @@lists_stack.push(self)
    end

    def addRow(raw_text)
        pos = calculate_text_position(raw_text)
        row = raw_text[pos..-1]

        pos = calculate_indent_position(raw_text)

        if pos > @@lists_stack[-1].indent_position

            prev_lists_stack_item = @@lists_stack[-1]
            # the following line pushes new list to the lists_stack in the constructor!
            nested_list = MarkdownList.new( MarkdownList.ordered_list_item?(raw_text) )
            nested_list.current_nesting_level = @current_nesting_level + 1
            nested_list.indent_position = pos
            
            prev_row = prev_lists_stack_item.rows[-1]
            if prev_row.is_a?(MarkdownList)
                #cannot be there
            else
                nested_list.text = prev_row
                #puts "Length: " + prev_lists_stack_item.rows.length.to_s
                prev_lists_stack_item.rows[-1] = nested_list
            end
            
            nested_list.addRow(raw_text)

        elsif pos < @@lists_stack[-1].indent_position

            @@lists_stack.pop
            @@lists_stack[-1].rows.append(row)

        else
            @@lists_stack[-1].rows.append(row)

        end
    end

    def calculate_indent_position(s)
        s.downcase
        pos = 0
        s.each_char do |c|
            if c != ' ' && c != '\t'
                break
            end
            pos += 1
        end
        return pos
    end
    def calculate_text_position(s)
        s.downcase
        pos = 0
        space_detected = false
        s.each_char do |c|
            if space_detected
                if c != ' ' && c != '\t' && c != '*' && c != '.' && !numeric?(c)
                    break
                end
            elsif c == ' ' || c == '\t'
                space_detected = true
            end
            pos += 1
        end
        return pos
    end

    def letter?(c)
        c.match?(/[[:alpha:]]/)
    end
      
    def numeric?(c)
        c.match?(/[[:digit:]]/)
    end

    def non_blank?(c)
        c.match?(/[[:graph:]]/)
    end

    def self.unordered_list_item?(raw_text)

        if res = /(\*\s?)(.*)/.match(raw_text)
            return true
        end
        return false
    end

    def self.ordered_list_item?(raw_text)

        if res = /\d[.]\s(.*)/.match(raw_text)
            return true
        end
        return false
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end

        if @is_ordered
            s += "<ol>\n"
        else
            s += "<ul>\n"
        end
        
        @rows.each do |r|
            if r.is_a?(MarkdownList)
                f_text = format_string(r.text)
                s += "\t<li>#{f_text}\n"
                s += r.to_html()
                s += "</li>\n"
            else
                f_text = format_string(r)
                #puts f_text
                s += "\t<li>#{f_text}</li>\n"
            end
        end

        if @is_ordered
            s += "</ol>\n"
        else
            s += "</ul>\n"
        end       

        return s
    end
end