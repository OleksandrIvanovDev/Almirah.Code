require_relative "base_document"

class Coverage < BaseDocument

    attr_accessor :top_doc
    attr_accessor :bottom_doc
    attr_accessor :covered_items

    def initialize(top_doc)
        super()
        @top_doc = top_doc
        @bottom_doc = nil

        @id = top_doc.id + "-" + "tests"
        @title = "Coverage Matrix: " + @id
        @covered_items = {}
    end

    def to_console
        puts "\e[35m" + "Traceability: " + @id + "\e[0m"
    end

    def to_html(nav_pane, output_file_path)

        html_rows = Array.new

        html_rows.append('')
        s = "<h1>#{@title}</h1>\n"
        s += "<table class=\"controlled\">\n"
        s += "\t<thead> <th>#</th> <th style='font-weight: bold;'>#{@top_doc.title}</th> <th>#</th> <th style='font-weight: bold;'>Test CaseId.StepId</th> </thead>\n"
        html_rows.append s

        sorted_items = @top_doc.controlled_items.sort_by { |w| w.id }

        sorted_items.each do |top_item|
            row = render_table_row top_item
            html_rows.append row
        end
        html_rows.append "</table>\n"

        self.save_html_to_file(html_rows, nav_pane, output_file_path)
        
    end

    def render_table_row(top_item)
        s = ""
        if top_item.coverage_links
            if top_item.coverage_links.length > 1
                id_color = "" # "style='background-color: #fff8c5;'" # disabled for now
            else
                id_color = ""
            end 
            top_item.coverage_links.each do |bottom_item|
                s += "\t<tr>\n"
                s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{top_item.text}</td>\n"
                
                if bottom_item.columns[-2].text.downcase == "pass"
                    test_step_color = "style='background-color: #cfc;'"
                elsif bottom_item.columns[-2].text.downcase == "fail"
                    test_step_color = "style='background-color: #fcc;'"
                else
                    test_step_color = ""
                end

                s += "\t\t<td class=\"item_id\" #{test_step_color}><a href=\"./../../tests/protocols/#{bottom_item.parent_doc.id}/#{bottom_item.parent_doc.id}.html##{bottom_item.id}\" class=\"external\">#{bottom_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{bottom_item.columns[1].text}</td>\n"
                s += "\t</tr>\n"
                @covered_items[top_item.id.to_s.downcase] = top_item
            end
        else
            s += "\t<tr>\n"
            s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{top_item.text}</td>\n"
            s += "\t\t<td class=\"item_id\"></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 42%;'></td>\n"
            s += "\t</tr>\n"
        end
        return s
    end
end
