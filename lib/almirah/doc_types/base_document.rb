# frozen_string_literal: true

require_relative '../relative_url'

class BaseDocument
  attr_accessor :title, :id, :dom, :headings, :output_rel_path

  class << self
    attr_accessor :show_decisions_link, :show_risks_link, :font_size
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
                        elsif instance_of?(RiskRegistryPage) || instance_of?(RisksOverview)
                          'overview.html'
                        elsif is_a? Decision # RiskRecord included
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
        file.puts font_size_style if BaseDocument.font_size
        file.puts "<script src=\"#{rel_to('scripts/main.js')}\"></script>"
        if @id == 'index'
          file.puts "<script type=\"module\" src=\"#{rel_to('scripts/orama_search.js')}\"></script>"
          file.puts "<link rel=\"stylesheet\" href=\"#{rel_to('css/search.css')}\">"
        elsif needs_chartjs?
          file.puts '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>'
        end
      elsif s.include?('{{HOME_BUTTON}}')
        file.puts index_link(rel_to('index.html'))
        file.puts decisions_link(rel_to('decisions/overview.html')) if BaseDocument.show_decisions_link
        file.puts risks_link(rel_to('risks/overview.html')) if BaseDocument.show_risks_link
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

  def risks_link(href)
    icon = '<span><i class="fa fa-exclamation-triangle" aria-hidden="true"></i></span>'
    %(<a id="risks_menu_item" href="#{href}">#{icon}&nbsp;Risks</a>)
  end

  # The Documents item (ADR-223): the same link on every page, the Index page
  # included, where it self-links — no Home variant. The element id stays
  # index_menu_item; the label is presentation, the id is an interface.
  def index_link(href)
    icon = '<span><i class="fa fa-home" aria-hidden="true"></i></span>'
    %(<a id="index_menu_item" href="#{href}">#{icon}&nbsp;Documents</a>)
  end

  # The inline override carrying the project.yml font_size (ADR-224). Emitted
  # after the main.css link only when the setting exists, so unconfigured
  # projects render exactly as before.
  def font_size_style
    "<style>:root { --almirah-font-size: #{BaseDocument.font_size}px; }</style>"
  end

  # Relative URL from this page to a target path under the build root.
  def rel_to(target)
    RelativeUrl.between(@output_rel_path, target)
  end
end
