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
end
