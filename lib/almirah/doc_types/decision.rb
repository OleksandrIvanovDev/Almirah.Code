# frozen_string_literal: true

require 'date'
require_relative 'persistent_document'
require_relative '../doc_items/heading'
require_relative '../doc_items/markdown_table'

class Decision < PersistentDocument # rubocop:disable Style/Documentation,Metrics/ClassLength
  attr_accessor :path, :sequence_number, :record_type, :html_rel_path, :root_prefix, :current_status,
                :start_date, :target_release_version, :specifications_path, :wrong_links_hash

  def initialize(file_path)
    super
    @path = file_path
    stem = File.basename(file_path, File.extname(file_path))
    assign_id_parts(stem)
    @current_status = nil
    @start_date = nil
    @target_release_version = nil
    @wrong_links_hash = {}
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

  def extract_current_status
    status_table = find_section_table('Status')
    return if status_table.nil?

    status_table.is_decision_status_table = true
    marker_rows = status_table.rows.select { |row| row[0].to_s.strip == '*' }
    @current_status = marker_rows.length == 1 ? marker_rows[0][-1].to_s.strip : nil
  end

  def extract_start_date
    dates = collect_dates('Status', 'Date') + collect_dates('Scope', 'Start Date')
    @start_date = dates.min
  end

  def extract_target_release_version
    @target_release_version = lookup_cell(
      section_name: 'Software Versions',
      key_column: 'Software Version Category',
      value_column: 'Software Version ID',
      key: 'Target Release Version'
    )
  end

  private

  def lookup_cell(section_name:, key_column:, value_column:, key:) # rubocop:disable Metrics/AbcSize
    table = find_section_table(section_name)
    return nil if table.nil?

    key_idx = column_index(table, key_column)
    value_idx = column_index(table, value_column)
    return nil if key_idx.nil? || value_idx.nil?

    row = table.rows.find { |r| r[key_idx].to_s.strip == key }
    return nil if row.nil?

    cell = row[value_idx].to_s.strip
    cell.empty? ? nil : cell
  end

  def find_section_table(section_name) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    in_section = false
    section_level = nil
    @items.each do |item|
      if item.is_a?(Heading)
        if !in_section && item.text.strip == section_name
          in_section = true
          section_level = item.level
        elsif in_section && item.level <= section_level
          return nil
        end
      elsif in_section && item.is_a?(MarkdownTable)
        return item
      end
    end
    nil
  end

  def collect_dates(section_name, column_name)
    table = find_section_table(section_name)
    return [] if table.nil?

    col_index = column_index(table, column_name)
    return [] if col_index.nil?

    table.rows.filter_map { |row| parse_dd_mm_yyyy(row[col_index]) }
  end

  def column_index(table, column_name)
    table.column_names.each_with_index do |name, idx|
      return idx if name.to_s.strip == column_name
    end
    nil
  end

  def parse_dd_mm_yyyy(value)
    return nil if value.nil?

    match = /\A(\d{2})-(\d{2})-(\d{4})\z/.match(value.to_s.strip)
    return nil unless match

    Date.new(match[3].to_i, match[2].to_i, match[1].to_i)
  rescue ArgumentError
    nil
  end

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
