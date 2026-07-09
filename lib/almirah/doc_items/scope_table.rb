# frozen_string_literal: true

require_relative 'controlled_table'
require_relative '../relative_url'

# Purpose-built controlled table for a Decision Record's `# Scope` section
# (ADR-210, slimmed to presentation only by ADR-222). It is modelled on
# ControlledTable but addresses its columns by header text (not position): it
# locates `#` and `Depends On` wherever the author placed them, along with the
# date columns whose cells are kept on one line (ENH-214).
#
# Rendering is the table's whole job: the `#` column is an anchored row number
# so individual Scope rows can be linked, and each Depends On reference renders
# as a clickable link to the referenced record.
class ScopeTable < ControlledTable
  attr_reader :cells

  def initialize(doc, markdown_table)
    @parent_doc = doc
    @parent_heading = doc.headings[-1]
    @column_names = markdown_table.column_names
    @is_separator_detected = markdown_table.is_separator_detected
    @cells = []
    @rows = []
    @col = locate_columns(@column_names)
    # The switch to ScopeTable happens on the first data row, so the source
    # MarkdownTable carries none yet; any it did are re-read for safety.
    markdown_table.rows.each { |cells| append_cells(cells) }
  end

  def add_row(row)
    append_cells(split_table_cells(row).map(&:strip))
    true
  end

  # Render as a controlled table: an anchored, centered step number in the `#`
  # column (so rows are linkable, like the protocol table) and formatted text
  # for every other cell.
  def to_html
    s = +''
    if @@html_table_render_in_progress
      s << "</table>\n"
      @@html_table_render_in_progress = false
    end
    s << "<table class=\"markdown_table\">\n\t<thead>"
    @column_names.each { |h| s << " <th>#{format_string(h.strip)}</th>" }
    s << " </thead>\n"
    @cells.each_with_index { |cells, i| s << row_html(cells, @rows[i]) }
    s << "</table>\n"
    s
  end

  private

  def locate_columns(column_names)
    index_of = lambda do |name|
      column_names.each_with_index { |h, i| return i if h.to_s.strip == name }
      nil
    end
    { step: index_of.call('#'), depends_on: index_of.call('Depends On'),
      start_date: index_of.call('Start Date'), target_date: index_of.call('Target Date') }
  end

  def append_cells(cells)
    @cells << cells
    @rows << { step: step_number(cells, @cells.length),
               depends_on: parse_depends_on(cell(cells, @col[:depends_on])) }
  end

  # The `#` column's integer when present; otherwise the row's 1-based position,
  # so a record without the column keeps each row as its own sequential step.
  def step_number(cells, row_position)
    return row_position if @col[:step].nil?

    value = cell(cells, @col[:step]).to_s.strip
    value.match?(/\A\d+\z/) ? value.to_i : row_position
  end

  def parse_depends_on(text)
    text.to_s.scan(/>\[([^\]]+)\]/).flatten.map(&:strip)
  end

  def cell(cells, index)
    return '' if index.nil?

    cells[index].to_s.strip
  end

  def row_html(cells, row)
    s = +"\t<tr>\n"
    cells.each_with_index { |value, index| s << cell_html(value, index, row) }
    s << "\t</tr>\n"
    s
  end

  def cell_html(value, index, row)
    return depends_on_html(row) if index == @col[:depends_on]
    return step_cell_html(value, row) if index == @col[:step]
    return date_cell_html(value) if [@col[:start_date], @col[:target_date]].include?(index)

    "\t\t<td>#{format_string(value.strip)}</td>\n"
  end

  # The Start/Target Date cells are kept on one line so a DD-MM-YYYY date never
  # wraps at its hyphens in a narrow column (ENH-214).
  def date_cell_html(value)
    "\t\t<td class=\"scope_date\">#{format_string(value.strip)}</td>\n"
  end

  # The `#` cell is a named anchor (id + name), mirroring the test-step number
  # column, so a Scope row can be deep-linked. Namespaced with `.scope.` so it
  # never collides with the Affected Documents controlled table, whose rows
  # anchor on the same `<record>.<step>` scheme on the same page.
  def step_cell_html(value, row)
    anchor = "#{@parent_doc.id}.scope.#{row[:step]}"
    "\t\t<td style=\"text-align: center;\">" \
      "<a name=\"#{anchor}\" id=\"#{anchor}\" href=\"##{anchor}\">#{format_string(value.strip)}</a></td>\n"
  end

  # Render each authored Depends On reference as a link to the referenced
  # record's page, resolved against the project-wide link registry. Unresolved
  # references render as broken-link spans.
  def depends_on_html(row)
    return "\t\t<td></td>\n" if row[:depends_on].empty?

    links = row[:depends_on].map { |ref| dependency_ref_html(ref) }
    "\t\t<td>#{links.join(', ')}</td>\n"
  end

  def dependency_ref_html(ref)
    target = TextLine.link_registry&.find_by_id(ref)
    if target.nil? || target.output_rel_path.nil?
      "<span class=\"broken_link\" title=\"Unresolved Depends On\">#{ref}</span>"
    else
      href = RelativeUrl.between(@parent_doc.output_rel_path, target.output_rel_path)
      "<a href=\"#{href}\" class=\"external\" title=\"Depends on #{target.id}\">#{ref}</a>"
    end
  end
end
