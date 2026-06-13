require_relative "doc_item"

class Image < DocItem

    attr_accessor :text
    attr_accessor :path

    def initialize(text, path)
        @text = text
        @path = path
    end

    def getTextWithoutSpaces
        return @text.split.join('-')
    end

    def to_html
        s = ''
        if @@html_table_render_in_progress
            s += "</table>\n"
            @@html_table_render_in_progress = false
        end

        alt = escape_attr(@text)
        src = safe_url(@path)
        if src.nil? # disallowed scheme: render inert rather than emitting it (ADR-188, SRS-098)
            s += "<p style=\"margin-top: 15px;\">[image: #{alt}]"
            return s
        end

        s += "<p style=\"margin-top: 15px;\"><img src=\"#{escape_attr(src)}\" alt=\"#{alt}\" "
        s += "href=\"javascript:void(0)\" onclick=\"image_OnClick(this)\">"
        return s
    end
end