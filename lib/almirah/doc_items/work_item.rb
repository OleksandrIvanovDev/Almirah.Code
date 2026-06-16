# frozen_string_literal: true

# A single Scope-table row of a Decision Record, modelled as a node in the
# per-row dependency network (ADR-194). Each work item carries its canonical
# identity (`<record>.<step>.<activity>`), the bounded per-row Status it reads
# its readiness from (ADR-193), and predecessor / successor edges spanning both
# intra-record (step order) and cross-record (Depends On) links.
#
# `predecessors` / `successors` follow the house list-of-single-key-hashes shape
# (ADR-197): each entry maps a readable `record.step.activity` label to the
# resolved WorkItem. Every cross-record edge additionally records whether it
# stays within a decision_groups folder (in-group) or crosses to another
# (cross-group); that tag is inert here and consumed by the critical-chain step
# (ADR-195). Readiness ignores it — a cross-group predecessor blocks exactly
# like an in-group one.
class WorkItem
  # Canonical phase order used only as the fallback for activity-type-aligned
  # resolution when the prerequisite has no row of the dependent's exact Item.
  ACTIVITY_ORDER = %w[Analysis Requirements Code Tests].freeze

  attr_reader :record_id, :step, :activity, :owner, :status, :depends_on_refs
  attr_accessor :predecessors, :successors, :cross_group_predecessor_labels, :resolved_dependencies

  def initialize(record_id:, step:, activity:, owner:, status:, depends_on_refs:) # rubocop:disable Metrics/ParameterLists
    @record_id = record_id
    @step = step
    @activity = activity.to_s.strip
    @owner = owner.to_s.strip
    @status = status.to_s.strip
    @depends_on_refs = depends_on_refs # array of record ref strings, e.g. ["ADR-193"]
    @predecessors = []
    @successors = []
    @cross_group_predecessor_labels = []
    # One entry per resolved Depends On reference, keyed by the authored ref:
    # { ref => { doc:, anchor:, label: } }. `anchor` is the target's resolved
    # work-item row anchor (nil when the target has no `#` step column, so the
    # link opens the record page); `label` is the resolved work item's id, for
    # the link tooltip. Used to render the Depends On cell as deep links.
    @resolved_dependencies = {}
  end

  def id
    "#{@record_id}.#{@step}.#{@activity}"
  end

  # The anchor of this work item's row in its rendered Scope table — the deep-link
  # target a dependent record points at. Namespaced with `.scope.` so it never
  # collides with the Affected Documents controlled table, whose rows anchor on
  # the same `<record>.<step>` scheme on the same page.
  def row_anchor
    "#{@record_id}.scope.#{@step}"
  end

  def add_resolved_dependency(ref, doc, anchor, label)
    @resolved_dependencies[ref] = { doc: doc, anchor: anchor, label: label }
  end

  def activity_rank
    ACTIVITY_ORDER.index(@activity) || ACTIVITY_ORDER.length
  end

  # A row is "started" once it leaves To Do; both In-Progress and Done count, so
  # a Done row whose predecessor never finished is still flagged as a violation.
  def started?
    @status == 'In-Progress' || @status == 'Done'
  end

  def done?
    @status == 'Done'
  end

  def add_predecessor(work_item, cross_group:)
    @predecessors << { work_item.id => work_item }
    @cross_group_predecessor_labels << work_item.id if cross_group
  end

  def add_successor(work_item)
    @successors << { work_item.id => work_item }
  end

  def predecessor_items
    @predecessors.map { |edge| edge.values.first }
  end

  # Same-record, lower-numbered steps — the intra-record (phase-order) edges.
  def intra_record_predecessors
    predecessor_items.select { |p| p.record_id == @record_id }
  end

  # Resolved Depends On edges into other records (in-group or cross-group alike).
  def cross_record_predecessors
    predecessor_items.reject { |p| p.record_id == @record_id }
  end

  # Kitted when every predecessor — intra- and cross-record, regardless of the
  # in-group / cross-group tag — is Done; trivially kitted when it has none.
  def fully_kitted?
    predecessor_items.all?(&:done?)
  end

  # A started row with an unfinished lower-numbered step in the same record.
  def phase_order_violation?
    started? && intra_record_predecessors.any? { |p| !p.done? }
  end

  # A started row whose resolved cross-record predecessor is not yet Done.
  def cross_record_violation?
    started? && cross_record_predecessors.any? { |p| !p.done? }
  end
end
