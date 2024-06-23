# frozen_string_literal: true

require_relative 'paragraph'

class Heading < Paragraph
  attr_accessor :level, :anchor_id, :section_number

  @@global_section_number = ''

  def initialize(doc, text, level)
    super(doc, text)
    @level = level

    if level != 0 # skip Doc Title
      if @@global_section_number == ''
        @@global_section_number = '1'
        (1..(level - 1)).each do |_n|
          @@global_section_number += '.1'
        end
      else
        previous_level = @@global_section_number.split('.').length

        if previous_level == level

          a = @@global_section_number.split('.')
          a[-1] = (a[-1].to_i + 1).to_s
          @@global_section_number = a.join('.')

        elsif level > previous_level

          a = @@global_section_number.split('.')
          a.push('1')
          @@global_section_number = a.join('.')

        else # level < previous_level

          a = @@global_section_number.split('.')
          delta = previous_level - level
          a.pop(delta)
          @@global_section_number = a.join('.')
          # increment
          a = @@global_section_number.split('.')
          a[-1] = (a[-1].to_i + 1).to_s
          @@global_section_number = a.join('.')
        end
      end
    end
    @section_number = @@global_section_number
    @anchor_id = get_anchor_text
  end

  def get_section_info
    if level.zero? # Doc Title
      @text
    else
      "#{@section_number} #{@text}"
    end
  end

  def get_anchor_text
    "#{@section_number}-#{getTextWithoutSpaces}"
  end

  def to_html
    s = ''
    if @@html_table_render_in_progress
      s += "</table>\n"
      @@html_table_render_in_progress = false
    end
    heading_level = level.to_s
    heading_text = get_section_info
    if level.zero?
      heading_level = 1.to_s # Render Doc Title as a regular h1
      heading_text = @text    # Doc Title does not have a section number
    end
    s += "<a name=\"#{@anchor_id}\"></a>\n"
    s += "<h#{heading_level}> #{heading_text} <a href=\"\##{@anchor_id}\" class=\"heading_anchor\">"
    s += "&para;</a></h#{heading_level}>"
    s
  end

  def get_html_link
    if @parent_doc.instance_of? Specification
      heading_text = get_section_info
      "<a href= class=\"external\">#{heading_text}</a>"
    end
  end

  def get_url
    "./specifications/#{parent_doc.id}/#{parent_doc.id}.html\##{@anchor_id}"
  end

  def self.reset_global_section_number
    @@global_section_number = ''
  end
end
