require 'yaml'

class ProjectConfiguration
    DEFAULT_WIP_LIMIT = 2

    attr_accessor :project_root_directory, :parameters

    def initialize(path)
        @project_root_directory = File.expand_path(path)
        @parameters = {}
        load_project_file
    end

    def load_project_file
            @parameters = YAML.load_file(@project_root_directory + '/project.yml')
    rescue Psych::SyntaxError => e
            puts "YAML syntax error: #{e.message}"
    rescue Errno::ENOENT
            puts 'Project file not found: project.yml'
    end

    def get_design_inputs
        if (@parameters.key? 'specifications') and (@parameters['specifications'].key? 'input')
            return @parameters['specifications']['input']
        end

        []
    end

    def get_repositories
        return @parameters['repositories'] if @parameters.key? 'repositories'

        []
    end

    def get_wip_limit
        return DEFAULT_WIP_LIMIT unless @parameters.is_a?(Hash)

        planning = @parameters['planning']
        return DEFAULT_WIP_LIMIT unless planning.is_a?(Hash)

        value = planning['wip_limit']
        return DEFAULT_WIP_LIMIT unless value.is_a?(Integer) && value.positive?

        value
    end

    def is_spec_db_shall_be_created
        if @parameters.key? 'output'
            @parameters['output'].each do |p|
               return true if p == 'specifications_db'
            end
        end
        false
    end
end
