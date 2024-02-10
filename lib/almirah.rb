require "thor"
require_relative "almirah/project"

class CLI < Thor
  desc "please <project_folder>", "say <project_folder>"
  option :results
    def please(project_folder)
      a = Almirah.new project_folder
      if options[:results]
        a.results options[:results]
      else
        a.default
      end
    end
end

class Almirah

  attr_accessor :project

  def initialize project_folder
    @project = Project.new project_folder, getGemRoot
  end

  def getGemRoot
    File.expand_path './..', File.dirname(__FILE__)
  end

  def results( test_run )
    @project.specifications_and_results test_run
  end

  def default
    @project.specifications_and_protocols
  end

end
