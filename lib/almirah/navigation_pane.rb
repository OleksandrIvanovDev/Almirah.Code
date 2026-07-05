class NavigationPane
  attr_accessor :specifications

  def initialize(specification)
    @doc = specification
  end

  def to_html
    return @doc.dom.section_tree_to_html if @doc.dom

    ''
  end
end
