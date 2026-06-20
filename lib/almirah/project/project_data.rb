require_relative '../link_registry'

class ProjectData
  attr_reader :specifications, :protocols, :traceability_matrices, :coverage_matrices, :source_files,
              :specifications_dictionary, :covered_specifications_dictionary, :implemented_specifications_dictionary,
              :implementation_matrices, :decisions, :decision_groups, :work_items, :link_registry

  def initialize
    @specifications = []
    @protocols = []
    @traceability_matrices = []
    @coverage_matrices = []
    @source_files = []
    @implementation_matrices = []
    @decisions = []
    # Insertion-ordered list of single-key hashes { "<first-level folder>" => [Decision, ...] },
    # grouping decision records by the planning folder they live in (see ADR-197).
    @decision_groups = []
    # Every Scope-row WorkItem across all decision records, keyed by its canonical
    # "<record>.<step>.<activity>" id (see ADR-194), populated by link_work_items.
    @work_items = {}

    @specifications_dictionary = {}
    @covered_specifications_dictionary = {}
    @implemented_specifications_dictionary = {}

    @link_registry = LinkRegistry.new
  end
end
