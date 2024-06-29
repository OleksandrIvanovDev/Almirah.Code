# frozen_string_literal: true

require_relative 'doc_item'

class MarkdownList < DocItem
  attr_accessor :rows, :text, :is_ordered, :indent_position, :current_nesting_level

  @@lists_stack = []

  def initialize(doc, is_ordered)
    super()
    @parent_doc = doc
    @parent_heading = doc.headings[-1]

    @rows = []
    @is_ordered = is_ordered
    @current_nesting_level = 0
    @indent_position = 0
    @text = ''

    @@lists_stack.push(self)
  end

  def add_row(raw_text)
    pos = calculate_text_position(raw_text)
    row = raw_text[pos..-1]

    pos = calculate_indent_position(raw_text)

    if pos > @@lists_stack[-1].indent_position

      prev_lists_stack_item = @@lists_stack[-1]
      # the following line pushes new list to the lists_stack in the constructor!
      nested_list = MarkdownList.new(@parent_doc, MarkdownList.ordered_list_item?(raw_text))
      nested_list.current_nesting_level = @current_nesting_level + 1
      nested_list.indent_position = pos

      prev_row = prev_lists_stack_item.rows[-1]
      if prev_row.is_a?(MarkdownList)
      # cannot be there
      else
        nested_list.text = prev_row
        # puts "Length: " + prev_lists_stack_item.rows.length.to_s
        prev_lists_stack_item.rows[-1] = nested_list
      end

      nested_list.add_row(raw_text)

    elsif pos < @@lists_stack[-1].indent_position

      @@lists_stack.pop while pos < @@lists_stack[-1].indent_position
      @@lists_stack[-1].rows.append(row)

    else
      @@lists_stack[-1].rows.append(row)

    end
  end

  def calculate_indent_position(s)
    s.downcase
    pos = 0
    s.each_char do |c|
      break if c != ' ' && c != '\t'

      pos += 1
    end
    pos
  end

  def calculate_text_position(s)
    s.downcase
    pos = 0
    state = 'looking_for_list_item_marker'
    s.each_char do |c|
      case state
      when 'looking_for_list_item_marker'
        if c == '*'
          state = 'looking_for_space'
        elsif numeric?(c)
          state = 'looking_for_dot'
        end
      when 'looking_for_dot'
        state = 'looking_for_space' if c == '.'
      when 'looking_for_space'
        state = 'looking_for_non_space' if [' ', '\t'].include?(c)
      when 'looking_for_non_space'
        if c != ' ' || c != '\t'
          state = 'list_item_text_pos_found'
          break
        end
      end
      pos += 1
    end
    pos
  end

  def letter?(c)
    c.match?(/[[:alpha:]]/)
  end

  def numeric?(c)
    c.match?(/[[:digit:]]/)
  end

  def non_blank?(c)
    c.match?(/[[:graph:]]/)
  end

  def self.unordered_list_item?(raw_text)
    res = /(\*\s?)(.*)/.match(raw_text)
    return true if res

    false
  end

  def self.ordered_list_item?(raw_text)
    res = /\d[.]\s(.*)/.match(raw_text)
    return true if res

    false
  end

  def to_html
    s = ''
    if @@html_table_render_in_progress
      s += "</table>\n"
      @@html_table_render_in_progress = false
    end

    s += if @is_ordered
           "<ol>\n"
         else
           "<ul>\n"
         end

    @rows.each do |r|
      if r.is_a?(MarkdownList)
        f_text = format_string(r.text)
        s += "\t<li>#{f_text}\n"
        s += r.to_html
        s += "</li>\n"
      else
        f_text = format_string(r)
        # puts f_text
        s += "\t<li>#{f_text}</li>\n"
      end
    end

    s += if @is_ordered
           "</ol>\n"
         else
           "</ul>\n"
         end

    s
  end
end
