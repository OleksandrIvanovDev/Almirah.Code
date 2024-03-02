require_relative "base_document"

class Specification < BaseDocument

    attr_accessor :up_link_doc_id
    attr_accessor :dictionary
    attr_accessor :controlled_items

    attr_accessor :items_with_uplinks_number
    attr_accessor :items_with_downlinks_number
    attr_accessor :items_with_coverage_number
    attr_accessor :duplicated_ids_number
    attr_accessor :last_used_id
    attr_accessor :last_used_id_number

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @items = Array.new
        @headings = Array.new
        @controlled_items = Array.new
        @dictionary = Hash.new

        @items_with_uplinks_number = 0
        @items_with_downlinks_number = 0
        @items_with_coverage_number = 0
        @duplicated_ids_number = 0
        @last_used_id = ""
        @last_used_id_number = 0

        @id = File.basename(fele_path, File.extname(fele_path)).downcase
        @up_link_doc_id = ""
    end

    def to_console
        puts ""
        puts "\e[33m" + "Specification: " + @title + "\e[0m"
        puts "-" * 53
        puts "| Number of Controlled Items           | %10d |" % @controlled_items.length
        puts "| Number of Items w/ Up-links          | %10d |" % @items_with_uplinks_number
        puts "| Number of Items w/ Down-links        | %10d |" % @items_with_downlinks_number

        # coverage
        if (@controlled_items.length > 0) && (@controlled_items.length == @items_with_coverage_number)
            puts "| Number of Items w/ Test Coverage     |\e[1m\e[32m %10d \e[0m|" % @items_with_coverage_number
        else
            puts "| Number of Items w/ Test Coverage     | %10d |" % @items_with_coverage_number
        end

        # duplicates
        if @duplicated_ids_number >0
            puts "| Duplicated Item Ids found            |\e[1m\e[31m %10d \e[0m|" % @duplicated_ids_number
        else
            puts "| Duplicated Item Ids found            | %10d |" % @duplicated_ids_number
        end
        
        puts "| Last used Item Id                    |\e[1m\e[37m %10s \e[0m|" % @last_used_id
        puts "-" * 53
    end

    def to_html(nav_pane, output_file_path)

        html_rows = Array.new

        html_rows.append('')

        @items.each do |item|    
            a = item.to_html
            a = adjust_internal_links(a, nav_pane.specifications)
            html_rows.append a
        end

        self.save_html_to_file(html_rows, nav_pane, output_file_path)
        
    end

    def adjust_internal_links(line, specifications)
        # check if there are internal links to md files and replace them
        if res = /<a\shref="(.*)"\sclass="external">.*<\/a>/.match(line)
            if res = /(\w*)[.]md/.match(res[1])
                id = res[1].downcase
                specifications.each do |spec|
                    if spec.id.downcase == id
                        line.sub!(/<a\shref="(.*)"\sclass="external">/,
                        "<a href=\".\\..\\#{id}\\#{id}.html\" class=\"external\">")
                        break
                    end
                end
            end
        end
        return line
    end

end