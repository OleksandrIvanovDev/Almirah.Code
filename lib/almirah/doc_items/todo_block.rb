require_relative "doc_item"

class TodoBlock < DocItem

    attr_accessor :text

    def initialize(text)
        @text = text
    end

    def to_html
        s = ''
        f_text = format_string(@text)
        if @@html_table_render_in_progress
            s += "</table>\n"
            @@html_table_render_in_progress = false
        end

        s += "<div class=\"todoblock\"><p>#{f_text}</div>\n"
        return s
    end
end