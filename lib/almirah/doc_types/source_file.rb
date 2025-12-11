# frozen_string_literal: true

require_relative 'persistent_document'

class SourceFile < PersistentDocument
  def initialize(fele_path, repository)
    super fele_path
    @id = File.basename(fele_path, File.extname(fele_path)).downcase
    @repository = repository
  end

  def to_console
    puts "\e[35mSource File: #{@id}\e[0m"
  end

  def to_html(_nav_pane, _output_file_path)
    puts "\e[33mSourceFile to_html not implemented yet\e[0m"
  end
end
