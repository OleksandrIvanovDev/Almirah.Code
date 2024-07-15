require 'yaml'

class Frontmatter
  attr_accessor :parameters

  def initialize(yaml_text_line)
    @parameters = YAML.safe_load(yaml_text_line)
  end
end
