# frozen_string_literal: true

require 'json'

# Prepare JSON database file for further indexing by other tools
class SpecificationsDb
  attr_accessor :specifications, :data

  def initialize(spec_list)
    @specifications = spec_list
    @data = []
    create_data
  end

  def create_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @specifications.each do |sp|
      sp.items.each do |i|
        if (i.instance_of? Paragraph) or (i.instance_of? ControlledParagraph)
          e = { 'document' => i.parent_doc.title, \
                'doc_color' => i.parent_doc.color, \
                'text' => i.text, \
                'heading_url' => i.parent_heading.get_url, \
                'heading_text' => i.parent_heading.get_section_info }
          @data.append e
        elsif i.instance_of? MarkdownList
          add_markdown_list_item_to_db(@data, i, i)
        elsif i.instance_of? MarkdownTable
          add_markdown_table_item_to_db(@data, i, i)
        end
      end
    end
  end

  def add_markdown_list_item_to_db(data, item_for_reference, item_to_process) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    e = nil
    item_to_process.rows.each do |r|
      if r.is_a?(MarkdownList)
        f_text = r.text
        e = {   'document' => item_for_reference.parent_doc.title, \
                'doc_color' => item_for_reference.parent_doc.color, \
                'text' => f_text, \
                'heading_url' => item_for_reference.parent_heading.get_url, \
                'heading_text' => item_for_reference.parent_heading.get_section_info }
        data << e
        add_markdown_list_item_to_db(data, item_for_reference, r)
      else
        f_text = r
        e = {   'document' => item_for_reference.parent_doc.title, \
                'doc_color' => item_for_reference.parent_doc.color, \
                'text' => f_text, \
                'heading_url' => item_for_reference.parent_heading.get_url, \
                'heading_text' => item_for_reference.parent_heading.get_section_info }
        data << e
      end
    end
    e
  end

  def add_markdown_table_item_to_db(data, item_for_reference, item_to_process)
    table_text = ''
    item_to_process.rows.each do |row|
      table_text += "| #{row.join(' | ')} |"
    end
    e = {   'document' => item_for_reference.parent_doc.title, \
            'doc_color' => item_for_reference.parent_doc.color, \
            'text' => table_text, \
            'heading_url' => item_for_reference.parent_heading.get_url, \
            'heading_text' => item_for_reference.parent_heading.get_section_info }
    data << e
  end

  def save(path)
    json = JSON.generate(@data)

    file = File.open("#{path}/specifications_db.json", 'w')
    file.puts json
    file.close
  end
end
