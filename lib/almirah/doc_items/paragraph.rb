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
        s = "<p>#{@text}"
        return s
    end
end