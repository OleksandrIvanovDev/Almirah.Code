require_relative 'doc_items/doc_item'
require_relative 'doc_items/heading'
require_relative 'doc_items/source_code_paragraph'

class SourceFileParser # rubocop:disable Style/Documentation
  def self.parse(doc, file_lines)
    # restart section numbering for each new document
    Heading.reset_global_section_number

    # There is no document without heading
    title = "[#{doc.repository}] : #{doc.id}"
    item = Heading.new(doc, title, 0)
    doc.items.append(item)
    doc.headings.append(item)
    doc.title = title

    item = Heading.new(doc, 'References', 2)
    doc.items.append(item)
    doc.headings.append(item)

    # main loop
    file_lines.each do |s| # rubocop:disable Metrics/BlockLength
      res = %r{<REQ>(.*)</REQ>}.match(s) # Document Referece Item
      next unless res

      # extract text between <REQ> and </REQ>
      # id will be generated automatically
      text = res[1].strip
      up_links = nil

      # check if it contains the uplink (one or many)
      # TODO: check this regular expression
      first_pos = text.length # for trailing commas
      tmp = text.scan(/(>\[(?>[^\[\]]|\g<0>)*\])/) # >[SRS-001], >[SYS-002]
      if tmp.length.positive?
        up_links = []
        tmp.each do |ul|
          lnk = ul[0]
          #
          doc_id = /([a-zA-Z]+)-\d+/.match(lnk) # SRS
          up_links << lnk.upcase if doc_id
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
      item = SourceCodeParagraph.new(doc, text)

      if up_links
        up_links.uniq! # remove duplicates
        doc.items_with_uplinks_number += 1 # for statistics
        up_links.each do |ul|
          next unless tmp = />\[(\S*)\]$/.match(ul) # >[(SRS-001)]

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
      if doc.dictionary.has_key?(item.id.to_s)
        doc.duplicated_ids_number += 1
        doc.duplicates_list.append(item)
      else
        doc.dictionary[item.id.to_s] = item # for fast search
      end
      doc.controlled_items.append(item) # for fast search
    end

    item = Heading.new(doc, 'Source Code', 2)
    doc.items.append(item)
    doc.headings.append(item)
  end
end
