require "thor"
require_relative "almirah/project"

class CLI < Thor
  desc "please <pass>", "say <pass>"
    def please(pass)
      Almirah.new().start(pass)
    end
end

class Almirah

  def getGemRoot
    File.expand_path './..', File.dirname(__FILE__)
  end

  def start(pass)

    prj = Project.new pass, getGemRoot

  end

end
