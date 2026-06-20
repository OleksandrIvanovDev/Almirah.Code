# frozen_string_literal: true

require_relative 'persistent_document'
require 'fileutils'
require 'rouge'

class SourceFile < PersistentDocument
  attr_accessor :root_path, :repository, :dictionary, :wrong_links_hash,
                :items_with_uplinks_number, :html_file_path, :specifications_path

  def initialize(repository_path, fele_path, repository_name)
    super fele_path
    @root_path = repository_path
    @id = File.basename(fele_path).downcase
    @repository = repository_name
    @html_file_path = '' # available only afer rendering

    @dictionary = {}
    @wrong_links_hash = {}

    @items_with_uplinks_number = 0

    # Calculate the relative path depth to determine correct number of parent directory symbols
    relative_path = @path.sub("#{@root_path}/", '')
    depth = relative_path.count('/') + 1 # +1 for the repository folder
    depth += 1 # for the source_files folder
    @specifications_path = "./#{'../' * depth}specifications/"
  end

  def to_console
    puts "\e[32mSource File: [#{@repository}] #{@id}\e[0m"
  end

  def to_html(output_file_path)
    html_rows = []

    html_rows.append('')

    @items.each do |item|
      a = item.to_html
      html_rows.append a
    end

    # make some nice lexed html
    source = File.read(@path.to_s)
    # Detect lexer from file extension
    # lexer = Rouge::Lexer.find_fancy(@path.to_s, source) || Rouge::Lexers::PlainText.new
    lexer = Rouge::Lexer.guess_by_filename(@path.to_s) || Rouge::Lexers::PlainText.new
    formatter = Rouge::Formatters::HTML.new

    # Add Base16 theme CSS
    theme_css = Rouge::Themes::Pastie.render(scope: '.highlight')
    html_rows.append "<style>\n#{theme_css}\n</style>"

    # Format the source code with syntax highlighting
    formatted_html = formatter.format(lexer.lex(source))

    # Add formatted code with highlighting styles
    html_rows.append '<div class="highlight" style="background-color:#f6f7f8;"><pre>'
    html_rows.append formatted_html
    html_rows.append '</pre></div>'

    save_to_file(html_rows, nil, output_file_path)
  end

  def save_to_file(html_rows, nav_pane, output_file_path)
    gem_root = File.expand_path './../../..', File.dirname(__FILE__)
    template_file = "#{gem_root}/lib/almirah/templates/page.html"

    file = File.open(template_file)
    file_data = file.readlines
    file.close

    output_file_path += "#{@repository}/"
    output_file_path += @path.sub("#{@root_path}/", '')
    output_file_path += '.html'
    @html_file_path = output_file_path
    FileUtils.mkdir_p(File.dirname(output_file_path))

    @output_rel_path = output_file_path.split('/build/', 2).last
    css_path = rel_to('css/main.css')
    js_path = rel_to('scripts/main.js')
    index_path = rel_to('index.html')

    file = File.open(output_file_path, 'w')
    file_data.each do |s|
      if s.include?('{{CONTENT}}')
        html_rows.each do |r|
          file.puts r
        end
      elsif s.include?('{{NAV_PANE}}')
        file.puts nav_pane.to_html if nav_pane
      elsif s.include?('{{DOCUMENT_TITLE}}')
        file.puts s.gsub! '{{DOCUMENT_TITLE}}', @title
      elsif s.include?('{{STYLES_AND_SCRIPTS}}')
        file.puts "<link rel=\"stylesheet\" href=\"#{css_path}\">"
        file.puts "<script src=\"#{js_path}\"></script>"
      elsif s.include?('{{HOME_BUTTON}}')
        file.puts "<a id=\"index_menu_item\" href=\"#{index_path}\"><span><i class=\"fa fa-info\" aria-hidden=\"true\"></i></span>&nbsp;Index</a>"
      elsif s.include?('{{GEM_VERSION}}')
        file.puts "(#{Gem.loaded_specs['Almirah'].version.version})"
      else
        file.puts s
      end
    end
    file.close
  end
end
