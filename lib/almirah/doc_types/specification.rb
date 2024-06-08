require_relative "base_document"

class Specification < BaseDocument

    attr_accessor :up_link_docs
    attr_accessor :dictionary
    attr_accessor :controlled_items
    attr_accessor :todo_blocks
    attr_accessor :wrong_links_hash

    attr_accessor :items_with_uplinks_number
    attr_accessor :items_with_downlinks_number
    attr_accessor :items_with_coverage_number
    attr_accessor :duplicated_ids_number
    attr_accessor :duplicates_list
    attr_accessor :last_used_id
    attr_accessor :last_used_id_number
    attr_accessor :color

    def initialize(fele_path)

        @path = fele_path
        @title = ""
        @items = Array.new
        @headings = Array.new
        @controlled_items = Array.new
        @dictionary = Hash.new
        @duplicates_list = Array.new
        @todo_blocks = Array.new
        @wrong_links_hash = Hash.new

        @items_with_uplinks_number = 0
        @items_with_downlinks_number = 0
        @items_with_coverage_number = 0
        @duplicated_ids_number = 0
        @last_used_id = ""
        @last_used_id_number = 0

        @color = 'bbb'

        @id = File.basename(fele_path, File.extname(fele_path)).downcase
        @up_link_docs = Hash.new
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
            #a = adjust_internal_links(a, nav_pane.specifications)
            html_rows.append a
        end

        self.save_html_to_file(html_rows, nav_pane, output_file_path)
        
    end

    def adjust_internal_links(line, specifications)
        # check if there are internal links to md files and replace them
        if tmp = /<a\shref="(.*)"\sclass="external">.*<\/a>/.match(line)
            if res = /(\w*)[.]md/.match(tmp[1])
                id = res[1].downcase
                res = /(\w*)[.]md(#.*)/.match(tmp[1])
                
                specifications.each do |spec|
                    if spec.id.downcase == id
                        if res && res.length > 2
                            anchor = res[2]
                            line.sub!(/<a\shref="(.*)"\sclass="external">/,
                            "<a href=\".\\..\\#{id}\\#{id}.html#{anchor}\" class=\"external\">")
                        else
                            line.sub!(/<a\shref="(.*)"\sclass="external">/,
                            "<a href=\".\\..\\#{id}\\#{id}.html\" class=\"external\">")
                        end
                        break
                    end
                end
            end
        end
        return line
    end

end