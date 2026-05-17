# frozen_string_literal: true

require_relative 'persistent_document'
require_relative '../doc_items/heading'
require_relative '../doc_items/markdown_table'

class Decision < PersistentDocument # rubocop:disable Style/Documentation
  attr_accessor :path, :sequence_number, :record_type, :html_rel_path, :root_prefix, :current_status

  def initialize(file_path)
    super
    @path = file_path
    stem = File.basename(file_path, File.extname(file_path))
    assign_id_parts(stem)
    @current_status = nil
  end

  def to_console
    puts "\e[36mDecision: #{@id}\e[0m"
  end

  def to_html(nav_pane, output_file_path)
    html_rows = []
    html_rows.append('')

    @items.each do |item|
      html_rows.append item.to_html
    end

    save_html_to_file(html_rows, nav_pane, output_file_path)
  end

  def extract_current_status # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    in_status_section = false
    status_level = nil
    status_table = nil
    @items.each do |item|
      if item.is_a?(Heading)
        if !in_status_section && item.text.strip == 'Status'
          in_status_section = true
          status_level = item.level
        elsif in_status_section && item.level <= status_level
          break
        end
      elsif in_status_section && item.is_a?(MarkdownTable)
        status_table = item
        break
      end
    end
    return if status_table.nil?

    status_table.is_decision_status_table = true
    marker_rows = status_table.rows.select { |row| row[0].to_s.strip == '*' }
    @current_status = marker_rows.length == 1 ? marker_rows[0][-1].to_s.strip : nil
  end

  private

  def assign_id_parts(stem)
    match = stem.match(/\A([A-Za-z]+)-(\d+)/)
    if match
      @id = "#{match[1]}-#{match[2]}".downcase
      @record_type = match[1].upcase
      @sequence_number = match[2]
    else
      @id = stem.downcase
      @record_type = nil
      @sequence_number = nil
    end
  end
end
