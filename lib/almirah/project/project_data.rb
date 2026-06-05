require_relative '../link_registry'

class ProjectData
  attr_reader :specifications, :protocols, :traceability_matrices, :coverage_matrices, :source_files,
              :specifications_dictionary, :covered_specifications_dictionary, :implemented_specifications_dictionary,
              :implementation_matrices, :decisions, :link_registry

  def initialize # rubocop:disable Metrics/MethodLength
    @specifications = []
    @protocols = []
    @traceability_matrices = []
    @coverage_matrices = []
    @source_files = []
    @implementation_matrices = []
    @decisions = []

    @specifications_dictionary = {}
    @covered_specifications_dictionary = {}
    @implemented_specifications_dictionary = {}

    @link_registry = LinkRegistry.new
  end
end
