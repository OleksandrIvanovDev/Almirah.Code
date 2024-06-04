require 'yaml'

class ProjectConfiguration

    attr_accessor :project_root_directory
    attr_accessor :parameters

    def initialize(path)
        @project_root_directory = path
        @parameters = {}
        load_project_file()
    end

    def load_project_file
        begin
            @parameters = YAML.load_file(@project_root_directory + '/project.yml') 
        rescue Psych::SyntaxError => e
            puts "YAML syntax error: #{e.message}"
          rescue Errno::ENOENT
            puts "Project file not found: project.yml"
        end
    end

    def get_design_inputs
        if (@parameters.key? 'specifications') and (@parameters['specifications'].key? 'input')
            return @parameters['specifications']['input']
        end
        return []
    end

    def is_spec_db_shall_be_created
        if (@parameters.key? 'output')
            @parameters['output'].each do |p|
               if p == 'specifications_db'
                return true
               end
            end
        end
        return false
    end

end