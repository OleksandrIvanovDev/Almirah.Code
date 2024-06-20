Gem::Specification.new do |s|
  s.name        = "Almirah"
  s.version     = "0.2.2"
  s.summary     = "Almirah"
  s.description = "The software part of the Almirah framework"
  s.authors     = ["Oleksandr Ivanov"]
  s.email       = "oleksandr.ivanov.development@gmail.com"
  s.homepage    = "http://almirah.site"
  s.files       = Dir['lib/**/*.rb'] + Dir['lib/**/*.html'] + Dir['lib/**/*.js'] + Dir['lib/**/*.css']
  s.license      = "MIT"
  s.executables  << "almirah" 
end