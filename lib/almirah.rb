require "thor"
require_relative "almirah/project"
require_relative "almirah/project_configuration"

class CLI < Thor
  option :results
  desc "please <project_folder>", "say <project_folder>"
    def please(project_folder)
      a = Almirah.new project_folder
      if options[:results]
        a.results( options[:results] )
      else
        a.default()
      end
    end

  desc "transform <project_folder>", "say <project_folder>"
  def transform(project_folder)
    a = Almirah.new project_folder
    a.transform "docx"
  end
end

class Almirah

  attr_accessor :project

  def initialize(project_folder)
    config = ProjectConfiguration.new project_folder
    @project = Project.new config
  end

  def getGemRoot()
    File.expand_path './..', File.dirname(__FILE__)
  end

  def results( test_run )
    @project.specifications_and_results test_run
  end

  def transform( file_extension )
    @project.transform file_extension
  end

  def default()
    @project.specifications_and_protocols
  end

end
