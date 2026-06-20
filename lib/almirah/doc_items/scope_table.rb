# frozen_string_literal: true

require_relative 'controlled_table'
require_relative 'work_item'

# Purpose-built controlled table for a Decision Record's `# Scope` section
# (ADR-194). It is modelled on ControlledTable but addresses its columns by
# header text (not position) and has no fixed link column: it locates `#`,
# `Item`, `Owner`, `Depends On`, and `Status` wherever the author placed them.
#
# Each data row becomes a WorkItem (the dependency-network node). The table also
# keeps a plain header-addressed cell grid (`cells`) so the ADR-193 Scope
# readers (owners / WIP / dates) keep working unchanged after the Scope section
# stopped being a plain MarkdownTable.
class ScopeTable < ControlledTable
  attr_reader :cells, :work_items

  def initialize(doc, markdown_table)
    @parent_doc = doc
    @parent_heading = doc.headings[-1]
    @column_names = markdown_table.column_names
    @is_separator_detected = markdown_table.is_separator_detected
    @cells = []
    @work_items = []
    @col = locate_columns(@column_names)
    # The switch to ScopeTable happens on the first data row, so the source
    # MarkdownTable carries none yet; any it did are re-read for safety.
    markdown_table.rows.each { |cells| append_cells(cells) }
  end

  def add_row(row)
    append_cells(split_table_cells(row).map(&:strip))
    true
  end

  # True when the table has a leading `#` step column, hence a per-row anchor a
  # dependent record can deep-link to (ADR-194).
  def step_column?
    !@col[:step].nil?
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
    @cells.each_with_index { |cells, i| s << row_html(cells, @work_items[i]) }
    s << "</table>\n"
    s
  end

  private

  def locate_columns(column_names)
    index_of = lambda do |name|
      column_names.each_with_index { |h, i| return i if h.to_s.strip == name }
      nil
    end
    { step: index_of.call('#'), item: index_of.call('Item'), owner: index_of.call('Owner'),
      depends_on: index_of.call('Depends On'), status: index_of.call('Status'),
      est_focused: index_of.call('Est (focused)'), est_safe: index_of.call('Est (safe)') }
  end

  def append_cells(cells)
    @cells << cells
    @work_items << build_work_item(cells)
  end

  def build_work_item(cells)
    WorkItem.new(
      record_id: @parent_doc.id,
      step: step_number(cells, @cells.length), # 1-based row order fallback
      activity: cell(cells, @col[:item]),
      owner: cell(cells, @col[:owner]),
      status: cell(cells, @col[:status]),
      depends_on_refs: parse_depends_on(cell(cells, @col[:depends_on])),
      **estimate_attrs(cells)
    )
  end

  # The ADR-195 estimate-derived attributes: focused and safe working-day
  # estimates (blank/unparseable -> 0) and the owning record's sequence number
  # (the critical-chain priority tiebreak).
  def estimate_attrs(cells)
    {
      focused_estimate: parse_estimate(cell(cells, @col[:est_focused])),
      safe_estimate: parse_estimate(cell(cells, @col[:est_safe])),
      record_sequence: @parent_doc.sequence_number.to_i
    }
  end

  # A Scope estimate cell as a non-negative number of working days (decimals
  # allowed); blank, unparseable, or negative values count as 0 (ADR-195).
  def parse_estimate(text)
    value = Float(text.to_s.strip, exception: false)
    value&.positive? ? value : 0.0
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

  def row_html(cells, work_item)
    s = +"\t<tr>\n"
    cells.each_with_index { |value, index| s << cell_html(value, index, work_item) }
    s << "\t</tr>\n"
    s
  end

  def cell_html(value, index, work_item)
    return depends_on_html(work_item) if index == @col[:depends_on]
    return step_cell_html(value, work_item) if index == @col[:step]

    "\t\t<td>#{format_string(value.strip)}</td>\n"
  end

  # The `#` cell is a named anchor (id + name), mirroring the test-step number
  # column, so a dependent record's Depends On link can target this row.
  def step_cell_html(value, work_item)
    anchor = work_item.row_anchor
    "\t\t<td style=\"text-align: center;\">" \
      "<a name=\"#{anchor}\" id=\"#{anchor}\" href=\"##{anchor}\">#{format_string(value.strip)}</a></td>\n"
  end

  # Render each authored Depends On reference as a link to the resolved target
  # record. When the target record has a `#` step column, the link deep-jumps to
  # the aligned activity row (its step anchor); otherwise it opens the record
  # page (no such anchor exists). Unresolved references render as broken-link
  # spans (ADR-194 also reports them on the console).
  def depends_on_html(work_item)
    return "\t\t<td></td>\n" if work_item.depends_on_refs.empty?

    links = work_item.depends_on_refs.map { |ref| dependency_ref_html(ref, work_item) }
    "\t\t<td>#{links.join(', ')}</td>\n"
  end

  def dependency_ref_html(ref, work_item)
    dep = work_item.resolved_dependencies[ref]
    return "<span class=\"broken_link\" title=\"Unresolved Depends On\">#{ref}</span>" if dep.nil?

    href = RelativeUrl.between(@parent_doc.output_rel_path, dep[:doc].output_rel_path, fragment: dep[:anchor])
    "<a href=\"#{href}\" class=\"external\" title=\"Depends on #{dep[:label]}\">#{ref}</a>"
  end
end
