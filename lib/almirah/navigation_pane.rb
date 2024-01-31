require_relative "doc_items/doc_item"
require_relative "specification"

class NavigationPane

    attr_accessor :specifications

    def initialize(specifications)
        @specifications = specifications
    end

    def to_html        
        s = "<ul class=\"fa-ul\">\n"
        @specifications.each do |spec|
            s += "\t<li><span class=\"fa-li\"><i class=\"fa fa-folder-open-o\"> </i></span> #{spec.key.downcase}\n"
                s += "\t\t<ul class=\"fa-ul\">\n"
                s += "\t\t\t<li><span class=\"fa-li\"><i class=\"fa fa-plus-square-o\"> </i></span>\n"
                s += "\t\t\t\t<a href=\".\\..\\#{spec.key.downcase }\\#{spec.key.downcase }.html\">#{spec.title}</a>\n"
                s += "\t\t\t</li>\n"
                s += "\t\t</ul>\n"
            s += "\t</li>\n"
        end
        s += "</ul>\n"
    end
end