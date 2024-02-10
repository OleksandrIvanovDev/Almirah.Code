
class NavigationPane

    attr_accessor :specifications

    def initialize(specifications)
        @specifications = specifications
    end

    def to_html        
        s = "<ul class=\"fa-ul\">\n"
        @specifications.each do |spec|
            s += "\t<li><span class=\"fa-li\"><i class=\"fa fa-folder-open-o\"> </i></span> #{spec.id}\n"
                s += "\t\t<ul class=\"fa-ul\">\n"
                s += "\t\t\t<li><span class=\"fa-li\"><i class=\"fa fa-plus-square-o\"> </i></span>\n"
                s += "\t\t\t\t<a href=\".\\..\\#{spec.id }\\#{spec.id }.html\">#{spec.title}</a>\n"
                s += "\t\t\t</li>\n"
                s += "\t\t</ul>\n"
            s += "\t</li>\n"
        end
        s += "</ul>\n"
    end
end