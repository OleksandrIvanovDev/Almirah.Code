# frozen_string_literal: true

require_relative 'project_data'

class DocLinker
  def self.link_all_source_files(project_data)
    result = false
    project_data.source_files.each do |f|
      project_data.specifications.each do |s|
        next unless f.up_link_docs.key?(s.id.to_s)

        link_source_file_to_spec(f, s)
        project_data.implemented_specifications_dictionary[s.id.to_s] = s
        result = true
      end
    end
    result
  end

  def self.link_protocol_to_spec(protocol, specification) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    top_document = specification
    bottom_document = protocol

    bottom_document.controlled_items.each do |item|
      next unless item.up_link_ids

      item.up_link_ids.each do |up_lnk|
        if top_document.dictionary.key?(up_lnk.to_s)

          top_item = top_document.dictionary[up_lnk.to_s]

          unless top_item.coverage_links
            top_item.coverage_links = []
            top_document.items_with_coverage_number += 1 # for statistics
          end
          top_item.coverage_links.append(item)
        elsif tmp = /^([a-zA-Z]+)-\d+/.match(up_lnk)
          # check if there is a non existing link with the right doc_id
          if tmp[1].downcase == top_document.id.downcase
            bottom_document.wrong_links_hash[up_lnk] = item
          end # SRS
        end
      end
    end
  end

  def self.link_source_file_to_spec(source_file, specification) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    top_document = specification
    bottom_document = source_file

    bottom_document.controlled_items.each do |item|
      next unless item.up_link_ids

      item.up_link_ids.each do |up_lnk|
        if top_document.dictionary.key?(up_lnk.to_s)

          top_item = top_document.dictionary[up_lnk.to_s]

          top_item.source_code_links = [] unless top_item.source_code_links
          top_item.source_code_links.append(item)
        elsif tmp = /^([a-zA-Z]+)-\d+/.match(up_lnk)
          # check if there is a non existing link with the right doc_id
          if tmp[1].downcase == top_document.id.downcase
            bottom_document.wrong_links_hash[up_lnk] = item
          end # SRS
        end
      end
    end
  end

  def self.link_two_specifications(doc_a, doc_b) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    if doc_b.up_link_docs.key?(doc_a.id.to_s)
      top_document = doc_a
      bottom_document = doc_b
    elsif doc_a.up_link_docs.key?(doc_b.id.to_s)
      top_document = doc_b
      bottom_document = doc_a
    else
      return false # no links
    end
    # puts "Link: #{doc_a.id} - #{doc_b.id}"
    bottom_document.controlled_items.each do |item|
      next unless item.up_link_ids

      item.up_link_ids.each do |up_lnk|
        if top_document.dictionary.key?(up_lnk.to_s)

          top_item = top_document.dictionary[up_lnk.to_s]

          unless top_item.down_links
            top_item.down_links = []
            top_document.items_with_downlinks_number += 1 # for statistics
          end
          top_item.down_links.append(item)
        elsif tmp = /^([a-zA-Z]+)-\d+/.match(up_lnk)
          # check if there is a non existing link with the right doc_id
          if tmp[1].downcase == top_document.id.downcase
            bottom_document.wrong_links_hash[up_lnk] = item
          end # SRS
        end
      end
    end
    true
  end
end
