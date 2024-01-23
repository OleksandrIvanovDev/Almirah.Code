require_relative "paragraph"

class ControlledParagraph < Paragraph

    attr_accessor :id

    def initialize(text, id)
        @text = text
        @id = id
    end

end