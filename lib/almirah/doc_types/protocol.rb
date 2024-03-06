require_relative "base_document"

class Protocol < BaseDocument

    attr_accessor :up_link_doc_id
    #attr_accessor :dictionary
    attr_accessor :controlled_items

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @items = Array.new
        @headings = Array.new
        @controlled_items = Array.new
        #@dictionary = Hash.new

        @id = File.basename(fele_path, File.extname(fele_path)).downcase
        @up_link_doc_id = Hash.new
    end

    def to_html(nav_pane, output_file_path)

        html_rows = Array.new

        html_rows.append('')

        @items.each do |item|    
            a = item.to_html
            html_rows.append a
        end

        self.save_html_to_file(html_rows, nav_pane, output_file_path)
        
    end

end