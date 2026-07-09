require_relative 'persistent_document'

class Protocol < PersistentDocument
  attr_accessor :specifications_path, :wrong_links_hash

  def initialize(fele_path)
    super
    @id = File.basename(fele_path, File.extname(fele_path)).downcase
    @specifications_path = './../../../specifications/'
    # The linker records dangling Req-IDs here as for every other linked
    # document type (ISSUE-226); without it a dangling reference crashed the build.
    @wrong_links_hash = {}
  end

  def to_html(nav_pane, output_file_path)
    html_rows = []

    html_rows.append('')

    @items.each do |item|
      a = item.to_html
      html_rows.append a
    end

    save_html_to_file(html_rows, nav_pane, output_file_path)
  end
end
