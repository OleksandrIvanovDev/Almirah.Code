
class NavigationPane

    attr_accessor :specifications

    def initialize(specification)
        @doc = specification
    end

    def to_html
        if  @doc.dom
            return @doc.dom.section_tree_to_html()
        else
            return ''
        end

        s = "<ul class=\"fa-ul\">\n"
        if @doc.headings && @doc.headings.length > 0
            @doc.headings.each do |heading|
                s += "\t<li><span class=\"fa-li\"><i class=\"fa fa-plus-square-o\"> </i></span>\n"
                s += "\t\t<a href=\"\##{heading.anchor_id}\">#{heading.text}</a>\n"
                    
                s += "\t</li>\n"
            end
        end
        s += "</ul>\n"
    end
end