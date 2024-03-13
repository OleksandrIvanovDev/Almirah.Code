require_relative "paragraph"

class Heading < Paragraph

    attr_accessor :level
    attr_accessor :anchor_id
    attr_accessor :section_number

    @@global_section_number = ""

    def initialize(text, level)
        @text = text
        @level = level
        @anchor_id = getTextWithoutSpaces()

        if @@global_section_number = ""
            @@global_section_number = "1"
            for n in 1..(level-1) do
                @@global_section_number += ".1"
            end
        else
            previous_level = @@global_section_number.split(".").length

            if previous_level == level

                a = @@global_section_number.split(".")
                a[-1] = (a[-1].to_i() +1).to_s
                @@global_section_number = a.join(".")

            elsif previous_level < level

                a = @@global_section_number.split(".")
                a.push("1")
                @@global_section_number = a.join(".")
            
            else # previous_level > level

                a = @@global_section_number.split(".")
                a.pop
                @@global_section_number = a.join(".")
            end
        end
        @section_number = @@global_section_number
    end

    def get_section_info
        s = @section_number + " " + @text
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end
        headingLevel = level.to_s 
        s += "<a name=\"#{@anchor_id}\"></a>\n"
        s += "<h#{headingLevel}> #{@text} <a href=\"\##{@anchor_id}\" class=\"heading_anchor\">"
        s += "&para;</a></h#{headingLevel}>"
        return s
    end
end