require_relative "doc_section"

class Document

    attr_accessor :root_section

    @@sections_stack = Array.new

    def initialize(headings_list)
        @root_section = nil

        build_sections_tree(headings_list)
    end

    def build_sections_tree(headings_list)

        headings_list.each do |h|

            if @root_section == nil

                s = DocSection.new(h)
                s.parent_section = nil
                @root_section = s
                @@sections_stack.push s

            elsif @@sections_stack[-1].heading.level == h.level

                s = DocSection.new(h)
                @@sections_stack[-2].sections.append(s)
                @@sections_stack[-1] = s

            elsif h.level > @@sections_stack[-1].heading.level

                s = DocSection.new(h)
                @@sections_stack[-1].sections.append(s)
                @@sections_stack.push s

            else
                while h.level < @@sections_stack[-1].heading.level
                    @@sections_stack.pop
                end

                s = DocSection.new(h)
                @@sections_stack[-2].sections.append(s)
                @@sections_stack[-1] = s
            end
        end
    end

    def section_tree_to_html
        s = ''
        s += "<a href=\"\#" + @root_section.heading.anchor_id.to_s + "\">" + @root_section.heading.text + "</a>\n"
        if @root_section.sections.length >0
            s += "\t<ul class=\"fa-ul\" style=\"margin-top: 2px;\">\n"
            @root_section.sections.each do |sub_section|
                s += sub_section.to_html()
            end
            s += "\t</ul>\n"
        end

        return s
    end
end