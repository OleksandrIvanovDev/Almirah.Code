# frozen_string_literal: true

require 'cgi'

# Shared HTML output-encoding helpers (ADR-188, SRS-096/097/098).
#
# Author-written Markdown is untrusted text and must be encoded for its HTML
# context at the point of output. These helpers are the single mechanism every
# renderer routes through, so coverage cannot drift item-by-item the way it did
# when only inline code and wiki-link text were escaped.
module HtmlSafe
  # URL schemes permitted in link/image targets. Anything else (notably
  # javascript:, data:, vbscript:) is treated as unsafe and rendered inert.
  ALLOWED_URL_SCHEMES = %w[http https mailto].freeze

  # Escapes literal text rendered into element content (the five characters:
  # & < > " '). Used for paragraph, heading, blockquote, table-cell and fenced
  # code block text. SRS-096.
  def escape_text(str)
    CGI.escapeHTML(str.to_s)
  end

  # Escapes a value interpolated into a quoted HTML attribute so it cannot
  # terminate the attribute or introduce new attributes/elements. SRS-097.
  def escape_attr(str)
    CGI.escapeHTML(str.to_s)
  end

  # Returns the URL when it is a relative/anchor reference or carries an allowed
  # scheme; returns nil for any other scheme so the caller can render the
  # link/image inert. SRS-098.
  def safe_url(raw)
    url = raw.to_s.strip
    scheme = url[/\A([a-z][a-z0-9+.-]*):/i, 1]
    return url if scheme.nil? # relative path or anchor reference

    ALLOWED_URL_SCHEMES.include?(scheme.downcase) ? url : nil
  end
end
