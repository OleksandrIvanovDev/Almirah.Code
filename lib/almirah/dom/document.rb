require_relative 'doc_section'

class Document
  attr_accessor :root_section

  def initialize(headings_list)
    @root_section = nil

    build_sections_tree(headings_list)
  end

  def build_sections_tree(headings_list)
    sections_stack = []
    headings_list.each do |h|
      if @root_section.nil?

        s = DocSection.new(h)
        s.parent_section = nil
        @root_section = s
        sections_stack.push s
        # one more artificial section copy if root is not a Document Title (level 0)
        if h.level.positive?
          a = DocSection.new(h)
          a.parent_section = @root_section
          @root_section.sections.append(a)
          sections_stack.push a
        end

      elsif sections_stack[-1].heading.level == h.level

        s = DocSection.new(h)
        s.parent_section = sections_stack[-1].parent_section
        sections_stack[-1].parent_section.sections.append(s)
        sections_stack[-1] = s

      elsif h.level > sections_stack[-1].heading.level

        s = DocSection.new(h)
        s.parent_section = sections_stack[-1]
        sections_stack[-1].sections.append(s)
        sections_stack.push s

      else
        sections_stack.pop while h.level < sections_stack[-1].heading.level
        sections_stack.push @root_section if sections_stack.empty?
        s = DocSection.new(h)
        if h.level == sections_stack[-1].heading.level
          s.parent_section = sections_stack[-1].parent_section
          sections_stack[-1].parent_section.sections.append(s)
        else
          s.parent_section = sections_stack[-1]
          sections_stack[-1].sections.append(s)
        end
        sections_stack[-1] = s
      end
    end
  end

  def section_tree_to_html
    s = ''
    s += "<a href=\"##{@root_section.heading.anchor_id}\">#{@root_section.heading.get_section_info}</a>\n"
    unless @root_section.sections.empty?
      s += "\t<ul class=\"fa-ul\" style=\"margin-top: 2px;\">\n"
      @root_section.sections.each do |sub_section|
        s += sub_section.to_html
      end
      s += "\t</ul>\n"
    end

    s
  end
end
