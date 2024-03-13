require_relative "text_line"

class DocItem < TextLine
    attr_accessor :parent_doc
    attr_accessor :parent_heading
    
    @parent_doc = nil
    @parent_heading = nil

    @@htmlTableRenderInProgress = false
end





