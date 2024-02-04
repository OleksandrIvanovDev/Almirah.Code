require_relative "base_document"

class Specification < BaseDocument

    attr_accessor :up_link_key
    attr_accessor :dictionary
    attr_accessor :controlled_paragraphs

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @items = Array.new
        @headings = Array.new
        @controlled_paragraphs = Array.new
        @dictionary = Hash.new

        @id = File.basename(fele_path, File.extname(fele_path)).upcase
        @up_link_key = ""
    end

end