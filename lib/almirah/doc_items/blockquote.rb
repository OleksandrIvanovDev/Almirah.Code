require_relative "doc_item"

class Blockquote < DocItem

    attr_accessor :text

    def initialize(text)
        @text = text
    end

    def to_html
        s = ''
        f_text = format_string(@text)
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end

        s += "<div class=\"blockquote\"><p>#{f_text}</div>\n"
        return s
    end
end