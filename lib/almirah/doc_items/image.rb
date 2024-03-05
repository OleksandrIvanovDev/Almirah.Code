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
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end

        s += "<p style=\"margin-top: 15px;\"><img src=\"#{@path}\" alt=\"#{@text}\">"
        return s
    end
end