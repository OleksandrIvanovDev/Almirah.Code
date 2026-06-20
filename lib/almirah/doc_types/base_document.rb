# frozen_string_literal: true

require_relative '../relative_url'

class BaseDocument
  attr_accessor :title, :id, :dom, :headings, :output_rel_path

  class << self
    attr_accessor :show_decisions_link
  end

  def initialize
    @items = []
    @headings = []
    @title = ''
    @id = ''
    @dom = nil
  end

  # Whether this page needs the Chart.js library loaded (overridden by the
  # planning pages that render charts).
  def needs_chartjs?
    false
  end

  def save_html_to_file(html_rows, nav_pane, output_file_path)
    gem_root = File.expand_path './../../..', File.dirname(__FILE__)
    template_file = "#{gem_root}/lib/almirah/templates/page.html"

    file = File.open(template_file)
    file_data = file.readlines
    file.close

    output_file_path += if @id == 'index'
                          "#{@id}.html"
                        elsif instance_of? DecisionsOverview
                          'overview.html'
                        elsif instance_of? CriticalChainPage
                          'critical-chain.html'
                        elsif instance_of? Decision
                          "#{@id}.html"
                        else
                          "#{@id}/#{@id}.html"
                        end
    @output_rel_path = output_file_path.split('/build/', 2).last
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
        file.puts "<link rel=\"stylesheet\" href=\"#{rel_to('css/main.css')}\">"
        file.puts "<script src=\"#{rel_to('scripts/main.js')}\"></script>"
        if @id == 'index'
          file.puts "<script type=\"module\" src=\"#{rel_to('scripts/orama_search.js')}\"></script>"
          file.puts "<link rel=\"stylesheet\" href=\"#{rel_to('css/search.css')}\">"
        elsif needs_chartjs?
          file.puts '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>'
        end
      elsif s.include?('{{HOME_BUTTON}}')
        if @id == 'index'
          file.puts home_link(rel_to('index.html'))
        else
          file.puts index_link(rel_to('index.html'))
        end
        if BaseDocument.show_decisions_link
          file.puts decisions_link(rel_to('decisions/overview.html'))
          file.puts critical_chain_link(rel_to('decisions/critical-chain.html'))
        end
      elsif s.include?('{{GEM_VERSION}}')
        file.puts "(#{Gem.loaded_specs['Almirah'].version.version})"
      else
        file.puts s
      end
    end
    file.close
  end

  def decisions_link(href)
    icon = '<span><i class="fa fa-gavel" aria-hidden="true"></i></span>'
    %(<a id="decisions_menu_item" href="#{href}">#{icon}&nbsp;Decision Records</a>)
  end

  def critical_chain_link(href)
    icon = '<span><i class="fa fa-link" aria-hidden="true"></i></span>'
    %(<a id="critical_chain_menu_item" href="#{href}">#{icon}&nbsp;Critical Chain</a>)
  end

  def index_link(href)
    icon = '<span><i class="fa fa-info" aria-hidden="true"></i></span>'
    %(<a id="index_menu_item" href="#{href}">#{icon}&nbsp;Index</a>)
  end

  def home_link(href)
    icon = '<span><i class="fa fa-home" aria-hidden="true"></i></span>'
    %(<a id="home_menu_item" href="#{href}">#{icon}&nbsp;Home</a>)
  end

  # Relative URL from this page to a target path under the build root.
  def rel_to(target)
    RelativeUrl.between(@output_rel_path, target)
  end
end
