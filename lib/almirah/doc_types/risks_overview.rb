# frozen_string_literal: true

require_relative 'base_document'
require_relative 'rpn_rendering'

# The all-registries summary page (ADR-219): build/risks/overview.html, the
# target of the top-menu Risks button. One table row per registry, in
# file-system order, with the columns Risk Registry (linked to the registry
# page), Total Risks, Open Risks, Highest RPN and Average RPN — the RPN
# aggregates computed over the registry's leading RPN group, ignoring records
# whose group value is blank.
class RisksOverview < BaseDocument
  include RpnRendering

  OPEN_EXCLUDED_STATUS = 'Closed'

  attr_accessor :registries, :configuration

  # `registries` is the ordered list of [name, records] pairs.
  def initialize(registries, configuration)
    super()
    @registries = registries
    @configuration = configuration
    @id = 'overview'
    @title = 'Risk Registries'
  end

  def to_console
    puts "\e[36mRisks Overview: #{@id}\e[0m"
  end

  def to_html(output_file_path)
    html_rows = ['']
    html_rows.append "<h1>#{@title}</h1>\n"
    html_rows.append render_registries_table
    save_html_to_file(html_rows, nil, output_file_path)
  end

  private

  def render_registries_table
    s = "<table class=\"controlled risks_overview\">\n"
    s += "\t<thead>\n"
    s += "\t\t<th>Risk Registry</th>\n"
    s += "\t\t<th>Total Risks</th>\n"
    s += "\t\t<th>Open Risks</th>\n"
    s += "\t\t<th>Highest RPN</th>\n"
    s += "\t\t<th>Average RPN</th>\n"
    s += "</thead>\n"
    @registries.each { |name, records| s += render_registry_row(name, records) }
    s + "</table>\n"
  end

  def render_registry_row(name, records)
    group = @configuration.get_risk_rpn_groups(name).first
    values = group ? records.filter_map { |r| r.rpn_value(group) } : []
    s = "\t<tr>\n"
    s += "\t\t<td class=\"item_text\" style='padding: 5px;'>\
<a name=\"#{name}\" id=\"#{name}\" href=\"./#{name}/overview.html\" class=\"external\" \
title=\"Risk Registry\">#{name}</a></td>\n"
    s += "\t\t<td class=\"item_rpn\">#{records.length}</td>\n"
    s += "\t\t<td class=\"item_rpn\">#{open_count(records)}</td>\n"
    s += render_highest_cell(values, group)
    s += render_average_cell(values)
    s + "\t</tr>\n"
  end

  # Every record whose marked status is not Closed counts as open — including
  # records with no current-status marker (ADR-219 keeps the count honest to
  # the marker; another terminal status is the registry preface's to document).
  def open_count(records)
    records.count { |r| r.current_status.to_s.strip != OPEN_EXCLUDED_STATUS }
  end

  # The worst risk's verdict carries up: the cell keeps the leading group's
  # threshold colouring. Blank without a group or computable values.
  def render_highest_cell(values, group)
    return "\t\t<td class=\"item_rpn\"></td>\n" if values.empty?

    highest = values.max
    classes = ['item_rpn', rpn_threshold_class(highest, group)].compact.join(' ')
    "\t\t<td class=\"#{classes}\">#{format_rpn(highest)}</td>\n"
  end

  def render_average_cell(values)
    return "\t\t<td class=\"item_rpn\"></td>\n" if values.empty?

    average = (values.sum.to_f / values.length).round(1)
    "\t\t<td class=\"item_rpn\">#{format_rpn(average)}</td>\n"
  end
end
