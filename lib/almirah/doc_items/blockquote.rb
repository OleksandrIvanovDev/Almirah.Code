require_relative "doc_item"

class Blockquote < DocItem

    attr_accessor :text

    def initialize(text)
        @text = text
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>\n\r"
            @@htmlTableRenderInProgress = false
        end

        s += "<div class=\"blockquote\"><p>#{@text}</div>\n\r"
        return s
    end
end