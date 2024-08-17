require 'thor'
require_relative 'almirah/project'
require_relative 'almirah/project_configuration'
require_relative 'almirah/project_template'
require_relative 'almirah/project_utility'

class CLI < Thor
  option :run
  desc 'please <project_folder>', 'Processes the folder'
  long_desc <<-LONGDESC
    Creates HTML representation of markdown files stored in <project_folder>

    Use --run option to specify exact test run ID for processing if required.

    For example: almirah please my_project --run 003

  LONGDESC
  def please(project_folder)
    a = Almirah.new project_folder
    if options[:run]
      a.run(options[:run])
    else
      a.default
    end
  end

  desc 'Creates project from template', ''
  long_desc <<-LONGDESC
    Creates default project structure in the <project_name> folder
  LONGDESC
  def create(project_name)
    Almirah.create_new_project_structure project_name
  end

  option :run
  desc 'combine <project_folder>', 'Combines all the test protocols'
  long_desc <<-LONGDESC
    Combines all the test protocols from the <project_folder>/tests/protocols folder

    Use --run option to specify exact test run ID from <project_folder>/tests/runs folder.

    For example: almirah combine my_project --run 003

    Result is stored as <project_folder>/build/combined.md
  LONGDESC
  def combine(project_folder)
    Almirah.create_project_utility project_folder
    if options[:run]
      Almirah.combine_run(options[:run])
    else
      Almirah.combine_protocols
    end
  end
end

class Almirah
  attr_accessor :project
  attr_accessor :project_utility

  def initialize(project_folder)
    config = ProjectConfiguration.new project_folder
    @project = Project.new config
  end

  def getGemRoot
    File.expand_path './..', File.dirname(__FILE__)
  end

  def run(test_run)
    @project.specifications_and_results test_run
  end

  def self.create_new_project_structure(project_name)
    ProjectTemplate.new project_name
  end

  def self.create_project_utility(project_folder)
    config = ProjectConfiguration.new project_folder
    @project_utility = ProjectUtility.new config
  end

  def self.combine_protocols
    @project_utility.combine_protocols
  end

  def self.combine_run(test_run)
    @project_utility.combine_run test_run
  end

  def default
    @project.specifications_and_protocols
  end
end
