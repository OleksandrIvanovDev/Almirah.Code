require "thor"
require_relative "almirah/specification"
require_relative "almirah/linker"
require_relative "almirah/html_render"

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
    # Documents
    documentList = Array.new

    # Parse
    Dir.glob( "#{pass}/**/*.md" ).each do |f|
      puts f
      spec = Specification.new(f)
      documentList.append(spec)
    end

    # Link
    linker = Linker.new
    linker.link(documentList[0], documentList[1])

    # Render
    FileUtils.remove_dir(pass + "/build", true)
    FileUtils.mkdir_p(pass + "/build/specifications")
    
    documentList.each do |spec|
      FileUtils.mkdir_p(pass + "/build/specifications/" + spec.key.downcase)
      HtmlRender.new( spec,
      getGemRoot() + "/lib/almirah/templates/page.html",
       "#{pass}/build/specifications/#{spec.key.downcase}/#{spec.key.downcase}.html" )
    end
  end

end
