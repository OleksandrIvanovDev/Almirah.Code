class ProjectData
  attr_reader :specifications, :protocols, :traceability_matrices, :coverage_matrices, :source_files,
              :specifications_dictionary, :covered_specifications_dictionary, :implemented_specifications_dictionary

  def initialize
    @specifications = []
    @protocols = []
    @traceability_matrices = []
    @coverage_matrices = []
    @source_files = []

    @specifications_dictionary = {}
    @covered_specifications_dictionary = {}
    @implemented_specifications_dictionary = {}
  end
end
