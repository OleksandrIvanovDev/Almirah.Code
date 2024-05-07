
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
    end
end