# frozen_string_literal: true

require 'pathname'

# Computes the relative URL between two generated pages, each given as a path
# relative to the build root (e.g. "decisions/release 0.4.1/adr-185.html").
# Produces forward-slash separators with spaces percent-encoded. Shared by all
# internal cross-document links (ADR-186).
module RelativeUrl
  module_function

  def between(from_output_rel, to_output_rel, fragment: nil)
    from_dir = Pathname.new(from_output_rel).dirname
    rel = Pathname.new(to_output_rel).relative_path_from(from_dir).to_s
    url = rel.split('/').map { |segment| encode_segment(segment) }.join('/')
    fragment && !fragment.empty? ? "#{url}##{fragment}" : url
  end

  def encode_segment(segment)
    segment.gsub(' ', '%20')
  end
end
