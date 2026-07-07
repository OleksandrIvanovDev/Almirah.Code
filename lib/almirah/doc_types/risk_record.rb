# frozen_string_literal: true

require_relative 'decision'
require_relative '../doc_items/controlled_table'

# A risk record (ADR-215): one Markdown file per risk, collected from the
# first-level subfolders of the project's risks/ folder, each subfolder being
# a risk registry. The record format is the decision-record format — filename
# letters-digits id, frontmatter title, Status table with a "*" current-state
# marker — so the type reuses Decision wholesale.
class RiskRecord < Decision
  # The first-level risks/ subfolder the record was collected from.
  attr_accessor :registry

  def to_console
    puts "\e[36mRisk Record: #{@id}\e[0m"
  end

  # The rendered HTML of the record section whose heading text equals
  # `section_name` (ADR-216). Empty when there is no such section — the
  # register renders it as an empty cell.
  def section_html(section_name)
    section_items(section_name).map(&:to_html).join
  end

  # The numeric value of the named section (ADR-217): its items' plain text
  # parsed as a Float. nil when the section is missing, empty, or not numeric —
  # the RPN cell renders blank rather than computing a broken record as safe.
  def section_numeric(section_name)
    texts = section_items(section_name).filter_map { |i| i.text if i.respond_to?(:text) }
    Float(texts.join(' ').strip, exception: false)
  end

  # The record's value for an RPN group (ADR-217): the product of its numeric
  # input sections. nil when any input is missing or not numeric — such a
  # record renders a blank cell and is ignored by the summary aggregates.
  def rpn_value(group)
    factors = group[:inputs].map { |input| section_numeric(input) }
    return nil if factors.any?(&:nil?)

    factors.reduce(:*)
  end

  # The distinct controlled-paragraph IDs the record's Affected Documents
  # Req-ID column links to (ADR-218), in the section's row order — the
  # IDs-only content of the register cell. Empty when the record carries no
  # Affected Documents section or its rows link nothing.
  def affected_document_ids
    table = section_items('Affected Documents').find { |i| i.is_a?(ControlledTable) }
    return [] if table.nil?

    table.rows.flat_map { |row| row.up_link_ids || [] }.uniq
  end

  private

  # The items between the heading whose text equals `section_name` and the
  # next heading of the same or a higher level; empty when no heading matches.
  def section_items(section_name)
    in_section = false
    section_level = nil
    collected = []
    @items.each do |item|
      if item.is_a?(Heading) && !in_section
        next unless item.text.strip == section_name

        in_section = true
        section_level = item.level
      elsif in_section
        break if item.is_a?(Heading) && item.level <= section_level

        collected.append item
      end
    end
    collected
  end
end
