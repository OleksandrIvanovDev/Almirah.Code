class SourceFileParser
  def self.parse(_doc, file_lines)
    # main loop
    file_lines.each do |s|
      # @content += "#{s}\n"
      puts s
    end
  end
end
