# frozen_string_literal: true

require_relative 'text_line'

class DocItem < TextLine # rubocop:disable Style/Documentation
  attr_accessor :parent_doc, :parent_heading

  @parent_doc = nil
  @parent_heading = nil

  @@html_table_render_in_progress = false # rubocop:disable Style/ClassVars

  def initialize(doc)
    super()
    @parent_doc = doc
    @parent_heading = doc.headings[-1]
  end

  def get_url
    ''
  end
end
