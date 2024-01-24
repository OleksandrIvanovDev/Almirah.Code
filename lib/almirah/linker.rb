require_relative "doc_items/doc_item"
require_relative "specification"

class Linker

    attr_accessor :field

    def initialize()
        @field = "field"
    end

    def link(doc_A, doc_B)

        if doc_A.key == doc_B.up_link_key
            top_document = doc_A
            bottom_document = doc_B
        elsif doc_B.key == doc_A.up_link_key
            top_document = doc_B
            bottom_document = doc_A
        else
            puts "No Links"
            return # no links
        end

        bottom_document.controlledParagraphs.each do |item|

            if top_document.dictionary.has_key?(item.up_link.to_s)

                topItem = top_document.dictionary[item.up_link.to_s]
                
                unless topItem.down_links
                    topItem.down_links = Array.new
                end
                topItem.down_links.append(item)

                #if tmp = /^([a-zA-Z]+)[-]\d+/.match(item.id)
                #    top_document.downlinkKey = tmp[1].upcase
                #end
            end
        end
    end
end