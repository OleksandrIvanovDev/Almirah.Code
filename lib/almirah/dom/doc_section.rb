class DocSection
  attr_accessor :sections, :heading, :parent_section

  def initialize(heading)
    @sections = []
    @heading = heading
    @parent_section = nil
  end

  def to_html # rubocop:disable Metrics/MethodLength
    s = ''
    s += "\t<li><span class=\"fa-li\"><i class=\"fa fa-square-o\"> </i></span>"
    s += "<a href=\"##{@heading.anchor_id}\">#{@heading.get_section_info}</a>\n"
    unless @sections.empty?
      s += "\t\t<ul class=\"fa-ul\">\n"
      @sections.each do |sub_section|
        s += sub_section.to_html
      end
      s += "\t\t</ul>\n"
    end
    s += "</li>\n"
    s
  end
end
