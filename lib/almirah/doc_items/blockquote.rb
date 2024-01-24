require_relative "doc_item"

class Blockquote < DocItem

    attr_accessor :text

    def initialize(text)
        @text = text
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>"
            @@htmlTableRenderInProgress = false
        end

        s += "<p>Note: #{@text}\n\r"
        return s
    end
end