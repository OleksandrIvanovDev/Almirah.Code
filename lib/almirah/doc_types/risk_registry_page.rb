# frozen_string_literal: true

require_relative 'base_document'
require_relative '../doc_items/heading'

# The registry page (ADR-216): build/risks/<registry>/overview.html holding
# the rendered registry preface (overview.md), when present, followed by the
# register table — one row per risk record with the implicit linked-ID and
# Title columns first, then the configured columns filled from each record's
# section matched by heading text. The Status column is reserved: it is filled
# from the record's current lifecycle status, never from a section.
class RiskRegistryPage < BaseDocument
  STATUS_COLUMN = 'Status'

  attr_accessor :registry, :records, :preface, :columns, :rpn_groups

  # `columns` is the configured per-registry list (ADR-216); nil means the
  # registry is not configured and gets the implicit columns plus Status only.
  # `rpn_groups` (ADR-217) appends one computed "<Name> RPN" column per group
  # after the configured columns; empty appends nothing.
  def initialize(registry, records, preface, columns, rpn_groups = [])
    super()
    @registry = registry
    @records = records
    @preface = preface
    @columns = columns.nil? ? [STATUS_COLUMN] : columns
    @rpn_groups = rpn_groups
    @id = 'overview'
    @title = preface_title || "Risk Registry: #{registry}"
  end

  def to_console
    puts "\e[36mRisk Registry: #{@registry}\e[0m"
  end

  def to_html(output_file_path)
    html_rows = ['']
    html_rows.concat preface_html
    html_rows.append render_register_table
    save_html_to_file(html_rows, nil, output_file_path)
  end

  private

  # The preface frontmatter title names the page; without it the registry does.
  def preface_title
    params = @preface&.frontmatter&.parameters
    params && params['title']
  end

  # The rendered overview.md items. The parser-injected level-0 title heading
  # is not authored preface content and is skipped.
  def preface_html
    return [] if @preface.nil?

    @preface.items.reject { |i| i.is_a?(Heading) && i.level.zero? }.map(&:to_html)
  end

  def render_register_table
    s = "<table class=\"controlled risk_register\">\n"
    s += "\t<thead>\n"
    s += "\t\t<th>#</th>\n"
    s += "\t\t<th>Title</th>\n"
    @columns.each { |c| s += "\t\t<th>#{c}</th>\n" }
    @rpn_groups.each { |g| s += "\t\t<th>#{g[:name]} RPN</th>\n" }
    s += "</thead>\n"
    @records.each { |doc| s += render_record_row(doc) }
    s + "</table>\n"
  end

  def render_record_row(doc)
    href = "./#{record_href(doc)}"
    s = "\t<tr>\n"
    s += "\t\t<td class=\"item_id\">\n"
    s += "\t\t\t<a name=\"#{doc.id}\" id=\"#{doc.id}\" href=\"#{href}\" title=\"Risk Record ID\">#{doc.id}</a>"
    s += "\t\t</td>\n"
    s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"#{href}\" class=\"external\">#{doc.title}</a></td>\n"
    @columns.each { |c| s += render_column_cell(doc, c) }
    @rpn_groups.each { |g| s += render_rpn_cell(doc, g) }
    s + "\t</tr>\n"
  end

  # The record page path relative to the registry page, which sits at the
  # registry root: the record's html_rel_path minus its registry segment.
  def record_href(doc)
    doc.html_rel_path.split('/', 2).last
  end

  def render_column_cell(doc, column)
    return "\t\t<td class=\"item_status\">#{doc.current_status}</td>\n" if column == STATUS_COLUMN

    "\t\t<td class=\"item_text\">#{doc.section_html(column)}</td>\n"
  end

  # The computed group cell (ADR-217): the product of the record's numeric
  # input sections, blank when any input is missing or not numeric, coloured
  # by the group's thresholds when configured.
  def render_rpn_cell(doc, group)
    value = rpn_value(doc, group)
    return "\t\t<td class=\"item_rpn\"></td>\n" if value.nil?

    classes = ['item_rpn', rpn_threshold_class(value, group)].compact.join(' ')
    "\t\t<td class=\"#{classes}\">#{format_rpn(value)}</td>\n"
  end

  def rpn_value(doc, group)
    factors = group[:inputs].map { |input| doc.section_numeric(input) }
    return nil if factors.any?(&:nil?)

    factors.reduce(:*)
  end

  # Acceptable at or below the acceptable bound, unacceptable at or above the
  # unacceptable bound, caution between them (the ALARP band); a lone bound
  # leaves the rest of the range as caution. nil when no thresholds configured.
  def rpn_threshold_class(value, group)
    if group[:acceptable] && value <= group[:acceptable]
      'rpn_acceptable'
    elsif group[:unacceptable] && value >= group[:unacceptable]
      'rpn_unacceptable'
    elsif group[:acceptable] || group[:unacceptable]
      'rpn_caution'
    end
  end

  # Whole products print as integers (8 * 3 -> 24, not 24.0).
  def format_rpn(value)
    value == value.to_i ? value.to_i.to_s : value.to_s
  end
end
