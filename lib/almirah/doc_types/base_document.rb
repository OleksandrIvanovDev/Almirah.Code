
class BaseDocument

    attr_accessor :path
    attr_accessor :items
    attr_accessor :headings
    attr_accessor :title
    attr_accessor :id

    def initialize(fele_path)

        @path = fele_path
        @items = Array.new
        @headings = Array.new
        @title = ""
        @id = ""
    end
end