require 'cgi'
require 'uri'
require_relative '../relative_url'
require_relative '../html_safe'

class TextLineToken
  attr_accessor :value

  def initialize
    @value = ''
  end
end

class ItalicToken < TextLineToken
  def initialize
    @value = '*'
  end
end

class BoldToken < TextLineToken
  def initialize
    @value = '**'
  end
end

class BoldAndItalicToken < TextLineToken
  def initialize
    @value = '***'
  end
end

class ParentheseLeft < TextLineToken
  def initialize
    @value = '('
  end
end

class ParentheseRight < TextLineToken
  def initialize
    @value = ')'
  end
end

class SquareBracketLeft < TextLineToken
  def initialize
    @value = '['
  end
end

class SquareBracketRight < TextLineToken
  def initialize
    @value = ']'
  end
end

class DoubleSquareBracketLeft < TextLineToken
  def initialize
    @value = '[['
  end
end

class DoubleSquareBracketRight < TextLineToken
  def initialize
    @value = ']]'
  end
end

class SquareBracketRightAndParentheseLeft < TextLineToken
  def initialize
    @value = ']('
  end
end

class BacktickToken < TextLineToken
  def initialize
    @value = '`'
  end
end

class InlineCodeToken < TextLineToken
  def initialize(raw)
    @value = raw
  end
end

class TextLineParser
  attr_accessor :supported_tokens

  def initialize
    @supported_tokens = []
    @supported_tokens.append(BoldAndItalicToken.new)
    @supported_tokens.append(BoldToken.new)
    @supported_tokens.append(ItalicToken.new)
    @supported_tokens.append(BacktickToken.new)
    @supported_tokens.append(DoubleSquareBracketLeft.new)
    @supported_tokens.append(DoubleSquareBracketRight.new)
    @supported_tokens.append(SquareBracketRightAndParentheseLeft.new)
    @supported_tokens.append(ParentheseLeft.new)
    @supported_tokens.append(ParentheseRight.new)
    @supported_tokens.append(SquareBracketLeft.new)
    @supported_tokens.append(SquareBracketRight.new)
    @supported_tokens.append(TextLineToken.new)
  end

  def tokenize(str)
    result = []
    sl = str.length
    si = 0
    while si < sl
      @supported_tokens.each do |t|
        tl = t.value.length
        if tl != 0 # literal is the last supported token in the list
          projected_end_position = si + tl - 1
          next if projected_end_position >= sl

          buf = str[si..projected_end_position]
          next unless buf == t.value

          if emphasis_token?(t) && !can_flank?(str, si, projected_end_position)
            append_literal(result, buf)
          else
            result.append(t)
          end
          si = projected_end_position + 1
          break
        else
          append_literal(result, str[si])
          si += 1
        end
      end
    end
    fuse_backticks(result)
  end

  private

  def fuse_backticks(tokens)
    result = []
    i = 0
    while i < tokens.length
      if tokens[i].instance_of?(BacktickToken)
        closer = next_backtick_index(tokens, i + 1)
        if closer
          raw = tokens[(i + 1)..(closer - 1)].map(&:value).join
          result.append(InlineCodeToken.new(raw))
          i = closer + 1
        else
          append_literal(result, '`')
          i += 1
        end
      else
        result.append(tokens[i])
        i += 1
      end
    end
    result
  end

  def next_backtick_index(tokens, start_idx)
    idx = start_idx
    while idx < tokens.length
      return idx if tokens[idx].instance_of?(BacktickToken)

      idx += 1
    end
    nil
  end

  def emphasis_token?(token)
    token.is_a?(ItalicToken) || token.is_a?(BoldToken) || token.is_a?(BoldAndItalicToken)
  end

  def append_literal(result, text)
    if !result.empty? && result[-1].instance_of?(TextLineToken)
      result[-1].value += text
    else
      literal = TextLineToken.new
      literal.value = text.dup
      result.append(literal)
    end
  end

  def can_flank?(str, start_idx, end_idx)
    left_flanking?(str, start_idx, end_idx) || right_flanking?(str, start_idx, end_idx)
  end

  def left_flanking?(str, start_idx, end_idx)
    after = char_at(str, end_idx + 1)
    return false if after.nil? || whitespace?(after)
    return true unless punctuation?(after)

    before = char_at(str, start_idx - 1)
    before.nil? || whitespace?(before)
  end

  def right_flanking?(str, start_idx, end_idx)
    before = char_at(str, start_idx - 1)
    return false if before.nil? || whitespace?(before)
    return true unless punctuation?(before)

    after = char_at(str, end_idx + 1)
    after.nil? || whitespace?(after)
  end

  def char_at(str, idx)
    return nil if idx.negative? || idx >= str.length

    str[idx]
  end

  def whitespace?(char)
    char.match?(/\s/)
  end

  def punctuation?(char)
    char.match?(/[[:punct:]]/)
  end
end

class TextLineBuilderContext
  # Literal (non-markup) text run. Subclasses encode it for the HTML context;
  # the base context leaves it untouched for plain reconstruction/unit tests.
  def literal_text(str)
    str
  end

  def italic(str)
    str
  end

  def bold(str)
    str
  end

  def bold_and_italic(str)
    str
  end

  def inline_code(str)
    str
  end

  def link(_link_text, link_url)
    link_url
  end

  def wiki_link(inner)
    "[[#{inner}]]"
  end
end

class TextLineBuilder
  attr_accessor :builder_context

  def initialize(builder_context)
    @builder_context = builder_context
  end

  def restore(token_list)
    result = ''
    return '' if token_list.nil?

    sub_list_url_text = nil
    sub_list_url_address = nil
    tl = token_list.length
    ti = 0
    while ti < tl
      case token_list[ti].class.name
      when 'ItalicToken'
        is_found = false
        ti_starting_position = ti
        # try to find closing part
        tii = ti + 1
        while tii < tl
          if token_list[tii].instance_of? ItalicToken
            sub_list = token_list[(ti + 1)..(tii - 1)]
            result += @builder_context.italic(restore(sub_list))
            ti = tii + 1
            is_found = true
            break
          end
          tii += 1
        end
        unless is_found
          result += '*'
          ti = ti_starting_position + 1
        end
      when 'BoldToken'
        is_found = false
        ti_starting_position = ti
        # try to find closing part
        tii = ti + 1
        while tii < tl
          if token_list[tii].instance_of? BoldToken
            sub_list = token_list[(ti + 1)..(tii - 1)]
            result += @builder_context.bold(restore(sub_list))
            ti = tii + 1
            is_found = true
            break
          end
          tii += 1
        end
        unless is_found
          result += '**'
          ti = ti_starting_position + 1
        end
      when 'BoldAndItalicToken'
        is_found = false
        ti_starting_position = ti
        # try to find closing part
        tii = ti + 1
        while tii < tl
          if token_list[tii].instance_of? BoldAndItalicToken
            sub_list = token_list[(ti + 1)..(tii - 1)]
            result += @builder_context.bold_and_italic(restore(sub_list))
            ti = tii + 1
            is_found = true
            break
          end
          tii += 1
        end
        unless is_found
          result += '***'
          ti = ti_starting_position + 1
        end
      when 'DoubleSquareBracketLeft'
        # wiki/Obsidian link: collect raw text up to the closing "]]"
        is_found = false
        ti_starting_position = ti
        tii = ti + 1
        while tii < tl
          if token_list[tii].instance_of?(DoubleSquareBracketRight)
            inner = token_list[(ti + 1)..(tii - 1)].map(&:value).join
            result += @builder_context.wiki_link(inner)
            ti = tii + 1
            is_found = true
            break
          end
          tii += 1
        end
        unless is_found
          result += '[['
          ti = ti_starting_position + 1
        end
      when 'SquareBracketLeft'
        # try to find closing part
        is_found = false
        tii = ti + 1
        ti_starting_position = ti
        while tii < tl
          case token_list[tii].class.name
          when 'SquareBracketRightAndParentheseLeft'
            sub_list_url_text = token_list[(ti + 1)..(tii - 1)]
            ti = tii + 1
            tiii = ti
            while tiii < tl
              case token_list[tiii].class.name
              when 'ParentheseRight'
                sub_list_url_address = token_list[(tii + 1)..(tiii - 1)]
                ti = tiii + 1
                is_found = true
                break
              end
              tiii += 1
            end
            break
          when 'SquareBracketRight'
            break
          end
          tii += 1
        end
        if is_found
          # URL is reconstructed raw (not via restore) so scheme classification
          # and file-path resolution see the original characters; link() applies
          # attribute escaping and the scheme allow-list (ADR-188).
          raw_url = (sub_list_url_address || []).map(&:value).join
          result += @builder_context.link(restore(sub_list_url_text), raw_url)
        else
          result += '['
          ti = ti_starting_position + 1
        end

      when 'InlineCodeToken'
        result += @builder_context.inline_code(token_list[ti].value)
        ti += 1
      when 'TextLineToken', 'ParentheseLeft', 'ParentheseRight', 'SquareBracketRight', 'DoubleSquareBracketRight'
        result += @builder_context.literal_text(token_list[ti].value)
        ti += 1
      else
        ti += 1
      end
    end
    result
  end
end

class TextLine < TextLineBuilderContext
  include HtmlSafe

  @@link_registry = nil
  @@broken_links = []

  class << self
    def link_registry=(registry)
      @@link_registry = registry
    end

    def link_registry
      @@link_registry
    end

    # Cross-document links that could not be resolved to a managed document,
    # collected during rendering for reporting (ADR-186, SRS-094).
    def broken_links
      @@broken_links
    end

    def reset_broken_links
      @@broken_links = []
    end

    def record_broken_link(document, target)
      @@broken_links << { document: document&.id, target: target }
    end
  end

  # The document that owns this text line. Used to resolve cross-document links
  # relative to the current page. nil for stand-alone text (e.g. unit tests).
  def owner_document
    nil
  end

  def format_string(str)
    tlp = TextLineParser.new
    tlb = TextLineBuilder.new(self)
    tlb.restore(tlp.tokenize(str))
  end

  # Literal text run, HTML-escaped for element content (ADR-188, SRS-096).
  def literal_text(str)
    escape_text(str)
  end

  def italic(str)
    "<i>#{str}</i>"
  end

  def bold(str)
    "<b>#{str}</b>"
  end

  def bold_and_italic(str)
    "<b><i>#{str}</i></b>"
  end

  def inline_code(str)
    "<code class=\"inline\">#{CGI.escapeHTML(str)}</code>"
  end

  def link(link_text, link_url)
    raw = link_url.to_s
    kind, target, fragment = classify_markdown_link(raw)
    case kind
    when :internal
      href = RelativeUrl.between(owner_document.output_rel_path, target.output_rel_path, fragment: fragment)
      "<a href=\"#{escape_attr(href)}\" class=\"external\">#{link_text}</a>"
    when :broken
      TextLine.record_broken_link(owner_document, raw)
      "<a href=\"#{escape_attr(raw)}\" class=\"broken_link\" title=\"Unresolved cross-document link\">#{link_text}</a>"
    else
      url = safe_url(raw)
      return link_text if url.nil? # disallowed scheme: render inert (ADR-188, SRS-098)

      "<a target=\"_blank\" rel=\"noopener\" href=\"#{escape_attr(url)}\" class=\"external\">#{link_text}</a>"
    end
  end

  # Resolves an Obsidian/wiki link "[[target#fragment|alias]]" to a managed
  # document by its unique id/filename, independent of folder (ADR-186).
  def wiki_link(inner)
    link_part, sep, alias_text = inner.partition('|')
    target, _hash, fragment = link_part.partition('#')
    display = (sep.empty? ? link_part : alias_text).strip
    display = link_part.strip if display.empty?

    doc = TextLine.link_registry&.find_by_id(target.strip)
    if doc && owner_document&.output_rel_path
      href = RelativeUrl.between(owner_document.output_rel_path, doc.output_rel_path,
                                 fragment: fragment.strip.empty? ? nil : fragment.strip)
      "<a href=\"#{href}\" class=\"external\">#{CGI.escapeHTML(display)}</a>"
    elsif owner_document&.output_rel_path
      TextLine.record_broken_link(owner_document, "[[#{inner}]]")
      "<span class=\"broken_link\" title=\"Unresolved wiki link\">#{CGI.escapeHTML(display)}</span>"
    else
      "[[#{inner}]]"
    end
  end

  private

  # Classifies a Markdown link target as :internal (a managed document, resolved
  # against the owning document's source directory), :broken (a local .md path
  # that does not resolve), or :external (everything else). ADR-186.
  def classify_markdown_link(raw)
    path_part, _sep, fragment = raw.partition('#')
    path_part = URI::DEFAULT_PARSER.unescape(path_part) # decode %20 etc. to match the real file path
    return [:external] unless local_markdown_path?(path_part)

    doc = owner_document
    return [:external] unless doc&.output_rel_path && doc.respond_to?(:path) && doc.path && TextLine.link_registry

    target = TextLine.link_registry.find_by_source(File.expand_path(path_part, File.dirname(doc.path)))
    if target
      [:internal, target, fragment.empty? ? nil : fragment]
    else
      [:broken]
    end
  end

  def local_markdown_path?(path_part)
    path_part.match?(/\.(md|markdown)\z/i) && !path_part.match?(%r{\A[a-z][a-z0-9+.-]*://}i)
  end
end
