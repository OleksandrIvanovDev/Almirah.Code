# frozen_string_literal: true

# Shared helper for the planning views: the non-empty decision groups (ADR-197)
# paired with their Scope-row work items. Used by the overview's group-segmented
# Gantt (ADR-201) and the dedicated Critical Chain page (ADR-195 / ENH-202).
module DecisionGrouping
  # [[group-name, [WorkItem, ...]], ...] in decision_groups (folder-encounter)
  # order, only groups that have at least one work item.
  def grouped_work_items
    by_record = @project.project_data.work_items.values.group_by(&:record_id)
    @project.project_data.decision_groups.filter_map do |group|
      name = group.keys.first
      items = group.values.first.flat_map { |doc| by_record[doc.id] || [] }
      [name, items] unless items.empty?
    end
  end
end
