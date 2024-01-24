require_relative "paragraph"

class Heading < Paragraph

    attr_accessor :level

    def initialize(text, level)
        @text = text
        @level = level
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>"
            @@htmlTableRenderInProgress = false
        end
        headingLevel = level.to_s
        itemTextNoSpaces = self.getTextWithoutSpaces
        s += "<a name=\"#{itemTextNoSpaces}\"></a>\n\r"
        s += "<h#{headingLevel}> #{@text} <a href=\"\##{itemTextNoSpaces}\">"
        s += "&para;</a></h#{headingLevel}>"
        return s
    end
end