
class BaseDocument

    attr_accessor :path
    attr_accessor :items
    attr_accessor :headings
    attr_accessor :title
    attr_accessor :id
    attr_accessor :dom

    def initialize(fele_path)

        @path = fele_path
        @items = Array.new
        @headings = Array.new
        @title = ""
        @id = ""
        @dom = nil
    end

    def save_html_to_file html_rows, nav_pane, output_file_path

        gem_root = File.expand_path './../../..', File.dirname(__FILE__)
        template_file =  gem_root + "/lib/almirah/templates/page.html"

        file = File.open( template_file )
        file_data = file.readlines
        file.close

        if @id == 'index'
            output_file_path += "#{@id}.html"
        else
            output_file_path += "#{@id}/#{@id}.html"
        end
        file = File.open( output_file_path, "w" )
        file_data.each do |s|
            if s.include?('{{CONTENT}}')
                html_rows.each do |r|
                    file.puts r
                end
            elsif s.include?('{{NAV_PANE}}')
                if nav_pane and 
                    file.puts nav_pane.to_html
                end
            elsif s.include?('{{DOCUMENT_TITLE}}')
                file.puts s.gsub! '{{DOCUMENT_TITLE}}', @title
            else
                file.puts s
            end
        end
        file.close
    end
end