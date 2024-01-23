require "thor"
require_relative "almirah/specification"
require_relative "almirah/html_render"

class CLI < Thor
  desc "please <pass>", "say <pass>"
    def please(pass)
      Almirah.new().start(pass)
    end
end

class Almirah
  def start(pass)
    # Documents
    documentList = Array.new

    Dir.glob( "#{pass}/**/*.md" ).each do |f|
      puts f
      spec = Specification.new(f)
      documentList.append(spec)
    end

    documentList.each do |spec|
      HtmlRender.new( spec,
      "D:\Projects\Proposals\Almirah\Almirah.Code\lib\almirah\templates\page.html",
       "#{pass}/#{spec.key.downcase}.html" )
    end
  end

end
