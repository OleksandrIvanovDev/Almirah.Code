require_relative "doc_item"

class DocFooter < DocItem

    def initialize
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end
        return s
    end

end