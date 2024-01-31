require_relative "paragraph"

class Heading < Paragraph

    attr_accessor :level
    attr_accessor :anchor_id

    def initialize(text, level)
        @text = text
        @level = level
        @anchor_id = self.getTextWithoutSpaces()
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>"
            @@htmlTableRenderInProgress = false
        end
        headingLevel = level.to_s 
        s += "<a name=\"#{@anchor_id}\"></a>\n\r"
        s += "<h#{headingLevel}> #{@text} <a href=\"\##{@anchor_id}\" class=\"heading_anchor\">"
        s += "&para;</a></h#{headingLevel}>"
        return s
    end
end