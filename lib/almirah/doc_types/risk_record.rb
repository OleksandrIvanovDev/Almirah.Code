# frozen_string_literal: true

require_relative 'decision'

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
  # `section_name` (ADR-216): every item between that heading and the next
  # heading of the same or a higher level. Empty when there is no such
  # section — the register renders it as an empty cell.
  def section_html(section_name)
    in_section = false
    section_level = nil
    rows = []
    @items.each do |item|
      if item.is_a?(Heading) && !in_section
        next unless item.text.strip == section_name

        in_section = true
        section_level = item.level
      elsif in_section
        break if item.is_a?(Heading) && item.level <= section_level

        rows.append item.to_html
      end
    end
    rows.join
  end
end
