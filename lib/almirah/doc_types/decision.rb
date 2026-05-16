# frozen_string_literal: true

require_relative 'base_document'

class Decision < BaseDocument # rubocop:disable Style/Documentation
  attr_accessor :path

  def initialize(file_path)
    super()
    @path = file_path
    @id = File.basename(file_path, File.extname(file_path)).downcase
    @title = extract_title(file_path) || @id
  end

  def to_console
    puts "\e[36mDecision: #{@id}\e[0m"
  end

  private

  def extract_title(file_path)
    File.foreach(file_path) do |line|
      if (match = /^\#\s+(.+)$/.match(line))
        return match[1].strip
      end
    end
    nil
  end
end
