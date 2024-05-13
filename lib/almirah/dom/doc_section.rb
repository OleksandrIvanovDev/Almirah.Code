class DocSection

    attr_accessor :sections
    attr_accessor :heading
    attr_accessor :parent_section

    def initialize(heading)
        @sections = Array.new
        @heading = heading
        @parent_section = nil
    end

    def to_html
        s = ''
        s += "\t<li><span class=\"fa-li\"><i class=\"fa fa-sticky-note-o\"> </i></span>"
        s += "<a href=\"\#" + @heading.anchor_id.to_s + "\">" + @heading.get_section_info + "</a>\n"
        if @sections.length >0
            s += "\t\t<ul class=\"fa-ul\">\n"
                @sections.each do |sub_section|
                    s += sub_section.to_html()
                end
            s += "\t\t</ul>\n"
        end
        s += "</li>\n"
        return s
    end

end