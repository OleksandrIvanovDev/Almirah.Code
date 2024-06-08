require 'json'
# Prepare JSON database file for further indexing by other tools
class SpecificationsDb

    attr_accessor :specifications
    attr_accessor :data

    def initialize(spec_list)
        @specifications = spec_list
        @data = []
        create_data
    end

    def create_data
        @specifications.each do |sp|
            sp.items.each do |i|
                if (i.instance_of? Paragraph) or (i.instance_of? ControlledParagraph)
                    e = {"document" => i.parent_doc.title, \
                        "doc_color" => i.parent_doc.color, \
                        "text" => i.text, \
                        "heading_url" => i.parent_heading.get_url(), \
                        "heading_text" => i.parent_heading.get_section_info()
                    }
                    @data.append e
                end
            end
        end
    end

    def save(path)
        json = JSON.generate(@data)

        file = File.open( path + "/specifications_db.json", "w" )
        file.puts json
        file.close
    end
end