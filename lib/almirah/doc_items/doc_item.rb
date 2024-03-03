require_relative "text_line"

class DocItem < TextLine
    attr_accessor :parent_doc
    
    @parent_doc = nil

    @@htmlTableRenderInProgress = false
end





