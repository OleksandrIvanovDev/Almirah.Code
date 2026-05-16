# frozen_string_literal: true

require_relative 'persistent_document'

class Decision < PersistentDocument # rubocop:disable Style/Documentation
  attr_accessor :path, :sequence_number, :record_type

  def initialize(file_path)
    super
    @path = file_path
    stem = File.basename(file_path, File.extname(file_path))
    assign_id_parts(stem)
  end

  def to_console
    puts "\e[36mDecision: #{@id}\e[0m"
  end

  def to_html(nav_pane, output_file_path)

        html_rows = Array.new

        html_rows.append('')

        @items.each do |item|
            a = item.to_html
            html_rows.append a
        end

        self.save_html_to_file(html_rows, nav_pane, output_file_path)
  end

  private

  def assign_id_parts(stem)
    match = stem.match(/\A([A-Za-z]+)-(\d+)/)
    if match
      @id = "#{match[1]}-#{match[2]}".downcase
      @record_type = match[1].upcase
      @sequence_number = match[2]
    else
      @id = stem.downcase
      @record_type = nil
      @sequence_number = nil
    end
  end
end
