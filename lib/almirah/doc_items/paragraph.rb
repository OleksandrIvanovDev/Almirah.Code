require_relative "doc_item"

class Paragraph < DocItem

    attr_accessor :text

    def initialize(text)
        @text = text
    end

    def getTextWithoutSpaces
        return @text.split.join('-')
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>"
            @@htmlTableRenderInProgress = false
        end

        s += "<p>" + format_string(@text)
        return s
    end
end