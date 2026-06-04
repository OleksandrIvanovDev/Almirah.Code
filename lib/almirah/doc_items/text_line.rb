require 'cgi'
require_relative '../relative_url'

class TextLineToken
  attr_accessor :value

  def initialize
    @value = ''
  end
end

class ItalicToken < TextLineToken
  def initialize # rubocop:disable Lint/MissingSuper
    @value = '*'
  end
end

class BoldToken < TextLineToken
  def initialize # rubocop:disable Lint/MissingSuper
    @value = '**'
  end
end

class BoldAndItalicToken < TextLineToken
  def initialize # rubocop:disable Lint/MissingSuper
    @value = '***'
  end
end

class ParentheseLeft < TextLineToken
  def initialize # rubocop:disable Lint/MissingSuper
    @value = '('
  end
end

class ParentheseRight < TextLineToken
  def initialize
    @value = ')'
  end
end

class SquareBracketLeft < TextLineToken
  def initialize # rubocop:disable Lint/MissingSuper
    @value = '['
  end
end

class SquareBracketRight < TextLineToken
  def initialize
    @value = ']'
  end
end

class SquareBracketRightAndParentheseLeft < TextLineToken
  def initialize
    @value = ']('
  end
end

class BacktickToken < TextLineToken
  def initialize # rubocop:disable Lint/MissingSuper
    @value = '`'
  end
end

class InlineCodeToken < TextLineToken
  def initialize(raw) # rubocop:disable Lint/MissingSuper
    @value = raw
  end
end

class TextLineParser
  attr_accessor :supported_tokens

  def initialize # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @supported_tokens = []
    @supported_tokens.append(BoldAndItalicToken.new)
    @supported_tokens.append(BoldToken.new)
    @supported_tokens.append(ItalicToken.new)
    @supported_tokens.append(BacktickToken.new)
    @supported_tokens.append(SquareBracketRightAndParentheseLeft.new)
    @supported_tokens.append(ParentheseLeft.new)
    @supported_tokens.append(ParentheseRight.new)
    @supported_tokens.append(SquareBracketLeft.new)
    @supported_tokens.append(SquareBracketRight.new)
    @supported_tokens.append(TextLineToken.new)
  end

  def tokenize(str) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity
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

  def fuse_backticks(tokens) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
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
          result += @builder_context.link(restore(sub_list_url_text), restore(sub_list_url_address))
        else
          result += '['
          ti = ti_starting_position + 1
        end

      when 'InlineCodeToken'
        result += @builder_context.inline_code(token_list[ti].value)
        ti += 1
      when 'TextLineToken', 'ParentheseLeft', 'ParentheseRight', 'SquareBracketRight'
        result += token_list[ti].value
        ti += 1
      else
        ti += 1
      end
    end
    result
  end
end

class TextLine < TextLineBuilderContext
  @@link_registry = nil # rubocop:disable Style/ClassVars

  class << self
    def link_registry=(registry)
      @@link_registry = registry # rubocop:disable Style/ClassVars
    end

    def link_registry
      @@link_registry
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
    target, fragment = resolve_cross_document_link(link_url.to_s)
    if target
      href = RelativeUrl.between(owner_document.output_rel_path, target.output_rel_path, fragment: fragment)
      "<a href=\"#{href}\" class=\"external\">#{link_text}</a>"
    else
      "<a target=\"_blank\" rel=\"noopener\" href=\"#{link_url}\" class=\"external\">#{link_text}</a>"
    end
  end

  private

  # Resolves a native Markdown link "[text](relative/path.md#fragment)" to a
  # managed document by resolving the relative path against the owning document's
  # source directory (ADR-186). Returns [target_document, fragment_or_nil] or nil.
  def resolve_cross_document_link(raw) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    path_part, _sep, fragment = raw.partition('#')
    return nil unless path_part =~ /\.(md|markdown)\z/i

    doc = owner_document
    return nil unless doc&.output_rel_path && doc.respond_to?(:path) && doc.path

    registry = TextLine.link_registry
    return nil unless registry

    target = registry.find_by_source(File.expand_path(path_part, File.dirname(doc.path)))
    return nil unless target

    [target, fragment.empty? ? nil : fragment]
  end
end
