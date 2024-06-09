require_relative "persistent_document"

class Protocol < PersistentDocument

    def initialize(fele_path)
        super
        @id = File.basename(fele_path, File.extname(fele_path)).downcase
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