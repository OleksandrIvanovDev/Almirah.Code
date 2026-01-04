class SourceCodeParagraph < ControlledParagraph
  @@source_code_links_counter = 'AAAA'
  def initialize(doc, text)
    super(doc, text, "SC-#{@@source_code_links_counter}")
    @@source_code_links_counter.next!
  end
end
