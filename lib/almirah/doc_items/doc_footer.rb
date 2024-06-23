require_relative "doc_item"

class DocFooter < DocItem

    def initialize
    end

    def to_html
        s = ''
        if @@html_table_render_in_progress
            s += "</table>\n"
            @@html_table_render_in_progress = false
        end
        return s
    end

end