require_relative "base_document"

class PersistentDocument < BaseDocument

    attr_accessor :path
    attr_accessor :items
    attr_accessor :controlled_items
    attr_accessor :headings
    attr_accessor :up_link_docs

    def initialize(fele_path)
        super()
        @path = fele_path
        @items = []
        @controlled_items = []
        @headings = []
        @up_link_docs = {}
    end

end