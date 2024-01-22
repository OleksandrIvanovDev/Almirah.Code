require "thor"

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
    end
  end

end
