# frozen_string_literal: true

require_relative 'base_document'

class Decision < BaseDocument # rubocop:disable Style/Documentation
  attr_accessor :path, :sequence_number, :record_type

  def initialize(file_path)
    super()
    @path = file_path
    stem = File.basename(file_path, File.extname(file_path))
    assign_id_parts(stem)
    @title = extract_title(file_path) || stem
  end

  def to_console
    puts "\e[36mDecision: #{@id}\e[0m"
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

  def extract_title(file_path)
    File.foreach(file_path) do |line|
      if (match = /^\#\s+(.+)$/.match(line))
        return match[1].strip
      end
    end
    nil
  end
end
