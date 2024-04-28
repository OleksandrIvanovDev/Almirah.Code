require "thor"
require_relative "almirah/project"

class CLI < Thor
  option :results
  desc "please <project_folder>", "say <project_folder>"
    def please(project_folder)
      a = Almirah.new project_folder
      if options[:results]
        a.results( options[:results], false )
      else
        a.default(false)
      end
    end

  desc "transform <project_folder>", "say <project_folder>"
  def transform(project_folder)
    a = Almirah.new project_folder
    a.transform "docx"
  end

  option :results
  desc "server <project_folder>", "say <project_folder>"
  def server(project_folder)
    a = Almirah.new project_folder
    if options[:results]
      a.results( options[:results], true )
    else
      a.default(true)
    end
  end
end

class Almirah

  attr_accessor :project

  def initialize(project_folder)
    @project = Project.new project_folder
  end

  def getGemRoot()
    File.expand_path './..', File.dirname(__FILE__)
  end

  def results( test_run, on_server )
    @project.on_server = on_server
    @project.specifications_and_results test_run
  end

  def transform( file_extension )
    @project.transform file_extension
  end

  def default(on_server)
    @project.on_server = on_server
    @project.specifications_and_protocols
  end

end
