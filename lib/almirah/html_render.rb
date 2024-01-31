require_relative "specification"
require_relative "doc_items/doc_item"
require_relative "navigation_pane"

class HtmlRender

    attr_accessor :template
    attr_accessor :htmlRows
    attr_accessor :outputFile
    attr_accessor :document
    attr_accessor :nav_pane

    def initialize(document, nav_pane, template, outputFile)

        @template = template
        @outputFile = outputFile
        @htmlRows = Array.new
        @document = document
        @nav_pane = nav_pane

        self.render()
        self.saveRenderToFile()
    end

    def render()
        self.htmlRows.append('')

        self.document.docItems.each do |item|    
            a = item.to_html
            self.htmlRows.append a
        end
    end

    def saveRenderToFile()

        file = File.open( self.template )
        file_data = file.readlines
        file.close

        file = File.open( self.outputFile, "w" )
        file_data.each do |s|
            if s.include?('{{CONTENT}}')
                self.htmlRows.each do |r|
                    file.puts r
                end
            elsif s.include?('{{NAV_PANE}}')
                file.puts self.nav_pane.to_html
            else
                file.puts s
            end
        end
        file.close
    end

end