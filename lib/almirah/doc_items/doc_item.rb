require_relative "text_line"

class DocItem < TextLine
    attr_accessor :parent_doc
    attr_accessor :parent_heading
    
    @parent_doc = nil
    @parent_heading = nil

    @@html_table_render_in_progress = false

    def get_url
        ''
    end
end





