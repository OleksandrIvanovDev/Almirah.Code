require_relative 'doc_items/text_line'
require_relative 'doc_items/doc_item'
require_relative 'doc_items/heading'
require_relative 'doc_items/paragraph'
require_relative 'doc_items/blockquote'
require_relative 'doc_items/code_block'
require_relative 'doc_items/todo_block'
require_relative 'doc_items/controlled_paragraph'
require_relative 'doc_items/markdown_table'
require_relative 'doc_items/controlled_table'
require_relative 'doc_items/image'
require_relative 'doc_items/markdown_list'
require_relative 'doc_items/doc_footer'

class DocParser
  def self.parse(doc, text_lines)
    temp_md_table = nil
    temp_md_list = nil
    temp_code_block = nil
    # restart section numbering for each new document
    Heading.reset_global_section_number

    text_lines.each do |s|
      if s.lstrip != ''
        if res = /^(\#{1,})\s(.*)/.match(s) # Heading

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          level = res[1].length
          value = res[2]

          if level == 1 && doc.title == ''
            doc.title = value
          end

          item = Heading.new(doc, value, level)
          doc.items.append(item)
          doc.headings.append(item)

        elsif res = /^%\s(.*)/.match(s) # Pandoc Document Title

          title = res[1]

          if doc.title == ''
            doc.title = title
          end

          item = Heading.new(doc, title, 0)
          doc.items.append(item)
          doc.headings.append(item)

        elsif res = /^\[(\S*)\]\s+(.*)/.match(s) # Controlled Paragraph

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          id = res[1].upcase
          text = res[2]
          up_links = nil

          # check if it contains the uplink (one or many)
          # TODO: check this regular expression
          first_pos = text.length # for trailing commas
          tmp = text.scan(/(>\[(?>[^\[\]]|\g<0>)*\])/) # >[SRS-001], >[SYS-002]
          if tmp.length > 0
            up_links = []
            tmp.each do |ul|
              lnk = ul[0]            
              # do not add links for the self document
              doc_id = /([a-zA-Z]+)-\d+/.match(lnk) # SRS
              if (doc_id) and (doc_id[1].downcase != doc.id.downcase)
                up_links << lnk.upcase
              end
              # try to find the real end of text
              pos = text.index(lnk)
              first_pos = pos if pos < first_pos
              # remove uplink from text
              text = text.split(lnk, 1).join('')
            end
            # remove trailing commas and spaces
            if text.length > first_pos
              first_pos -= 1
              text = text[0..first_pos].strip
            end
          end

          # since we already know id and text
          item = ControlledParagraph.new(doc, text, id)

          if up_links
            up_links.uniq! #remove duplicates
            doc.items_with_uplinks_number += 1 # for statistics
            up_links.each do |ul|
              next unless tmp = />\[(\S*)\]$/.match(ul) # >[SRS-001]

              up_link_id = tmp[1]

              item.up_link_ids = [] unless item.up_link_ids

              item.up_link_ids.append(up_link_id)

              if tmp = /^([a-zA-Z]+)-\d+/.match(up_link_id) # SRS
                doc.up_link_docs[tmp[1].downcase.to_s] = tmp[1].downcase # multiple documents could be up-linked
              end
            end
          end

          doc.items.append(item)
          # for statistics
          if doc.dictionary.has_key?(id.to_s)
            doc.duplicated_ids_number += 1
            doc.duplicates_list.append(item)
          else
            doc.dictionary[id.to_s] = item # for fast search
          end
          doc.controlled_items.append(item) # for fast search

          # for statistics
          n = /\d+/.match(id)[0].to_i
          if n > doc.last_used_id_number
            doc.last_used_id = id
            doc.last_used_id_number = n
          end

        elsif res = /^!\[(.*)\]\((.*)\)/.match(s) # Image

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          img_text = res[1]
          img_path = res[2]

          item = Image.new(img_text, img_path)
          item.parent_doc = doc
          item.parent_heading = doc.headings[-1]

          doc.items.append(item)

        elsif res = /^(\*\s+)(.*)/.match(s)   # check if unordered list start

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end

          row = res[2]

          if temp_md_list
            temp_md_list.addRow(s)
          else
            item = MarkdownList.new(doc, false)
            item.addRow(s)
            temp_md_list = item
          end

        elsif res = /^\d[.]\s(.*)/.match(s)   # check if ordered list start

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end

          row = res[1]

          if temp_md_list
            temp_md_list.addRow(s)
          else
            item = MarkdownList.new(doc, true)
            item.addRow(s)
            temp_md_list = item
          end

        elsif s[0] == '|' # check if table

          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          if res = /^[|](-{3,})[|]/.match(s) # check if it is a separator first

            if temp_md_table
            # separator is found after heading - just skip it
            else
              # separator out of table scope consider it just as a regular paragraph
              item = Paragraph.new(s)
              item.parent_doc = doc
              item.parent_heading = doc.headings[-1]
              doc.items.append(item)
            end

          elsif res = /^[|](.*[|])/.match(s) # check if it looks as a table

            row = res[1]

            if temp_md_table
              # check if it is a controlled table
              unless temp_md_table.addRow(row)
                temp_md_table = ControlledTable.new(temp_md_table, doc)
                temp_md_table.parent_doc = doc
                temp_md_table.addRow(row)
              end
            else
              # start table from heading
              temp_md_table = MarkdownTable.new(row)
              temp_md_table.parent_doc = doc
            end
          end

        elsif res = /^>(.*)/.match(s) # check if blockquote

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          item = Blockquote.new(res[1])
          item.parent_doc = doc
          item.parent_heading = doc.headings[-1]
          doc.items.append(item)

        elsif res = /^```(\w*)/.match(s) # check if code block

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          suggested_format = ''
          suggested_format = res[1] if res.length == 2

          if temp_code_block
            # close already opened block
            doc.items.append(temp_code_block)
            temp_code_block = nil
          else
            # start code block
            temp_code_block = CodeBlock.new(suggested_format)
            temp_code_block.parent_doc = doc
          end

        elsif res = /^TODO:(.*)/.match(s) # check if TODO block

          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            doc.items.append temp_md_list
            temp_md_list = nil
          end

          text = '**TODO**: ' + res[1]

          item = TodoBlock.new(text)
          item.parent_doc = doc
          item.parent_heading = doc.headings[-1]
          doc.items.append(item)
          doc.todo_blocks.append(item)

        else # Reqular Paragraph
          if temp_md_table
            doc.items.append temp_md_table
            temp_md_table = nil
          end
          if temp_md_list
            if MarkdownList.unordered_list_item?(s) || MarkdownList.ordered_list_item?(s)
              temp_md_list.addRow(s)
              next
            else
              doc.items.append temp_md_list
              temp_md_list = nil
            end
          end
          if temp_code_block
            temp_code_block.code_lines.append(s)
          else
            item = Paragraph.new(s)
            item.parent_doc = doc
            item.parent_heading = doc.headings[-1]
            doc.items.append(item)
          end
        end
      elsif temp_md_list
        doc.items.append temp_md_list
        temp_md_list = nil # lists are separated by emty line from each other
      end
    end
    # Finalize non-closed elements
    if temp_md_table
      doc.items.append temp_md_table
      temp_md_table = nil
    end
    if temp_md_list
      doc.items.append temp_md_list
      temp_md_list = nil
    end
    if temp_code_block
      doc.items.append temp_code_block
      temp_code_block = nil
    end
    # Add footer to close opened tables if any
    item = DocFooter.new
    item.parent_doc = doc
    doc.items.append(item)
  end
end
