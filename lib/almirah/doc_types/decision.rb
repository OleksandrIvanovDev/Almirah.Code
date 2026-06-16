# frozen_string_literal: true

require 'date'
require_relative 'persistent_document'
require_relative '../doc_items/heading'
require_relative '../doc_items/markdown_table'
require_relative '../doc_items/scope_table'

class Decision < PersistentDocument # rubocop:disable Style/Documentation,Metrics/ClassLength
  attr_accessor :path, :sequence_number, :record_type, :html_rel_path, :root_prefix, :current_status,
                :start_date, :target_date, :target_release_version, :specifications_path, :wrong_links_hash,
                :owners, :scope_table

  def initialize(file_path)
    super
    @path = file_path
    stem = File.basename(file_path, File.extname(file_path))
    assign_id_parts(stem)
    @current_status = nil
    @start_date = nil
    @target_date = nil
    @target_release_version = nil
    @wrong_links_hash = {}
    @owners = []
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

  def extract_target_date
    dates = collect_dates('Status', 'Date') + collect_dates('Scope', 'Target Date')
    @target_date = dates.max
  end

  def extract_target_release_version
    @target_release_version = lookup_cell(
      section_name: 'Software Versions',
      key_column: 'Software Version Category',
      value_column: 'Software Version ID',
      key: 'Target Release Version'
    )
  end

  # The distinct, first-seen-ordered list of non-empty Owner cells in the Scope
  # table. Empty when there is no Scope table, no Owner column, or no owner values.
  # The Owner column is located by header text, not position.
  def extract_owners
    @owners = []
    table = find_section_table('Scope')
    return if table.nil?

    owner_idx = column_index(table, 'Owner')
    return if owner_idx.nil?

    table.cells.each do |row|
      owner = row[owner_idx].to_s.strip
      @owners << owner unless owner.empty? || @owners.include?(owner)
    end
  end

  # The parsed Scope ScopeTable (ADR-194), or nil when the record has no Scope
  # section. Memoised so the work-item network and the readers share one table.
  def extract_scope_table
    table = find_section_table('Scope')
    @scope_table = table.is_a?(ScopeTable) ? table : nil
  end

  # The Scope rows as WorkItem nodes (ADR-194); empty when there is no ScopeTable.
  def scope_work_items
    @scope_table ? @scope_table.work_items : []
  end

  # A record declares prerequisites when any of its rows carries a Depends On
  # reference; the overview Kit column is empty otherwise.
  def declared_dependencies?
    scope_work_items.any? { |wi| wi.depends_on_refs.any? }
  end

  # Kitted when every one of its work items is (a record with no rows is kitted).
  def fully_kitted?
    scope_work_items.all?(&:fully_kitted?)
  end

  # A started row blocked by an unsatisfied cross-record predecessor — the
  # overview emphasises such a record, matching the console warning.
  def kit_started_violation?
    scope_work_items.any?(&:cross_record_violation?)
  end

  # One entry per Scope row whose row Status is In-Progress, yielding that row's
  # owner. Rows without an owner, or not In-Progress, contribute nothing. The
  # per-row Status is read directly and is independent of the record's lifecycle
  # status. Owner and Status columns are located by header text, not position.
  def in_progress_owner_tally # rubocop:disable Metrics/AbcSize
    table = find_section_table('Scope')
    return [] if table.nil?

    owner_idx = column_index(table, 'Owner')
    status_idx = column_index(table, 'Status')
    return [] if owner_idx.nil? || status_idx.nil?

    table.cells.filter_map do |row|
      owner = row[owner_idx].to_s.strip
      next if owner.empty?

      owner if row[status_idx].to_s.strip == 'In-Progress'
    end
  end

  def effective_status_on(date) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    table = find_section_table('Status')
    return nil if table.nil?

    date_idx = column_index(table, 'Date')
    status_idx = column_index(table, 'Status')
    return nil if date_idx.nil? || status_idx.nil?

    best_idx = nil
    best_date = nil
    table.rows.each_with_index do |row, i|
      parsed = parse_dd_mm_yyyy(row[date_idx])
      next if parsed.nil? || parsed > date

      if best_date.nil? || parsed > best_date || (parsed == best_date && i > best_idx)
        best_date = parsed
        best_idx = i
      end
    end
    return nil if best_idx.nil?

    status = table.rows[best_idx][status_idx].to_s.strip
    status.empty? ? nil : status
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
      elsif in_section && (item.is_a?(MarkdownTable) || item.is_a?(ScopeTable))
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

    table.cells.filter_map { |row| parse_dd_mm_yyyy(row[col_index]) }
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
