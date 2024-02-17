
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

    def save_html_to_file html_rows, nav_pane, output_file_path

        gem_root = File.expand_path './../../..', File.dirname(__FILE__)
        template_file =  gem_root + "/lib/almirah/templates/page.html"

        file = File.open( template_file )
        file_data = file.readlines
        file.close

        output_file_path += "#{@id}/#{@id}.html"
        file = File.open( output_file_path, "w" )
        file_data.each do |s|
            if s.include?('{{CONTENT}}')
                html_rows.each do |r|
                    file.puts r
                end
            elsif s.include?('{{NAV_PANE}}')
                if nav_pane
                    file.puts nav_pane.to_html
                end
            else
                file.puts s
            end
        end
        file.close
    end
end