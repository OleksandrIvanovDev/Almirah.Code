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
    combList = documentList.combination(2)
    combList.each do |c|
      linker.link(c[0], c[1])
    end

    # Render
    FileUtils.remove_dir(pass + "/build", true)
    FileUtils.mkdir_p(pass + "/build/specifications")
    
    documentList.each do |spec|

      img_src_dir = pass + "/specifications/" + spec.key.downcase + "/img"
      img_dst_dir = pass + "/build/specifications/" + spec.key.downcase + "/img"
     
      FileUtils.mkdir_p(img_dst_dir)

      if File.directory?(img_src_dir)
        FileUtils.copy_entry( img_src_dir, img_dst_dir )
      end

      HtmlRender.new( spec,
      getGemRoot() + "/lib/almirah/templates/page.html",
       "#{pass}/build/specifications/#{spec.key.downcase}/#{spec.key.downcase}.html" )
    end
  end

end
