require_relative "doc_item"

class Paragraph < DocItem

    attr_accessor :text

    def initialize(doc, text)
        @parent_doc = doc
        @parent_heading = doc.headings[-1]
        @text = text
    end

    def getTextWithoutSpaces
        return @text.split.join('-').downcase
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