# frozen_string_literal: true

class BaseDocument # rubocop:disable Style/Documentation
  attr_accessor :title, :id, :dom, :headings

  def initialize
    @items = []
    @headings = []
    @title = ''
    @id = ''
    @dom = nil
  end

  def save_html_to_file(html_rows, nav_pane, output_file_path) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    gem_root = File.expand_path './../../..', File.dirname(__FILE__)
    template_file = "#{gem_root}/lib/almirah/templates/page.html"

    file = File.open(template_file)
    file_data = file.readlines
    file.close

    output_file_path += if @id == 'index'
                          "#{@id}.html"
                        else
                          "#{@id}/#{@id}.html"
                        end
    file = File.open(output_file_path, 'w')
    file_data.each do |s| # rubocop:disable Metrics/BlockLength
      if s.include?('{{CONTENT}}')
        html_rows.each do |r|
          file.puts r
        end
      elsif s.include?('{{NAV_PANE}}')
        file.puts nav_pane.to_html if nav_pane
      elsif s.include?('{{DOCUMENT_TITLE}}')
        file.puts s.gsub! '{{DOCUMENT_TITLE}}', @title
      elsif s.include?('{{STYLES_AND_SCRIPTS}}')
        if @id == 'index'
          file.puts '<script type="module" src="./scripts/orama_search.js"></script>'
          file.puts '<link rel="stylesheet" href="./css/search.css">'
          file.puts '<link rel="stylesheet" href="./css/main.css">'
          file.puts '<script src="./scripts/main.js"></script>'
        elsif instance_of? Specification
          file.puts '<link rel="stylesheet" href="../../css/main.css">'
          file.puts '<script src="../../scripts/main.js"></script>'
        elsif instance_of? Traceability
          file.puts '<link rel="stylesheet" href="../../css/main.css">'
          file.puts '<script src="../../scripts/main.js"></script>'
        elsif instance_of? Coverage
          file.puts '<link rel="stylesheet" href="../../css/main.css">'
          file.puts '<script src="../../scripts/main.js"></script>'
        elsif instance_of? Protocol
          file.puts '<link rel="stylesheet" href="../../../css/main.css">'
          file.puts '<script src="../../../scripts/main.js"></script>'
        end
      elsif s.include?('{{GEM_VERSION}}')
        file.puts "(#{Gem.loaded_specs['Almirah'].version.version})"
      else
        file.puts s
      end
    end
    file.close
  end
end
