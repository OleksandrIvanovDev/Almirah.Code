Gem::Specification.new do |s|
  s.name        = "Almirah"
  s.version     = "0.0.3"
  s.summary     = "Almirah"
  s.description = "The software part of the Almirah system"
  s.authors     = ["Oleksandr Ivanov"]
  s.email       = "oleksandr.ivanov.development@gmail.com"
  s.files       = Dir['lib/**/*.rb'] 
  s.files.append("lib/almirah/templates/page.html")
  s.homepage    =
    "https://rubygems.org/gems/almirah"
  s.license      = "MIT"
  s.executables  << "almirah" 
end