require_relative "base_document"

class Traceability < BaseDocument

    attr_accessor :top_doc
    attr_accessor :bottom_doc
    attr_accessor :items

    def initialize(top_doc, bottom_doc)

        @top_doc = top_doc
        @bottom_doc = bottom_doc

        @items = Array.new
        @headings = Array.new

        @id = top_doc.id + "-" + bottom_doc.id
        @title = "Traceability Matrix: " + @id
    end

    def to_console
        puts "\e[35m" + "Traceability: " + @id + "\e[0m"
    end

    def to_html(nav_pane, output_file_path)

        html_rows = Array.new

        html_rows.append('')
        s = "<h1>#{@title}</h1>\n"
        s += "<table class=\"controlled\">\n"
        s += "\t<thead> <th>#</th> <th style='font-weight: bold;'>#{@top_doc.title}</th> <th>#</th> <th style='font-weight: bold;'>#{@bottom_doc.title}</th> </thead>\n"
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
        if tmp = /^([a-zA-Z]+)[-]\d+/.match(top_item.id)
            top_doc_name = tmp[1].downcase
        end
        s = ""
        if top_item.down_links
            if top_item.down_links.length > 1
                id_color = "style=' background-color: #fff8c5;'"
            else
                id_color = ""
            end 
            top_item.down_links.each do |bottom_item|
                s += "\t<tr>\n"
                s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"./../#{top_doc_name}/#{top_doc_name}.html\" class=\"external\">#{top_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{top_item.text}</td>\n"
                s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_doc_name}/#{top_doc_name}.html\" class=\"external\">#{bottom_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{bottom_item.text}</td>\n"
                s += "\t</tr>\n"
            end
        else
            s += "\t<tr>\n"
            s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_doc_name}/#{top_doc_name}.html\" class=\"external\">#{top_item.id}</a></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 42%;'>#{top_item.text}</td>\n"
            s += "\t\t<td class=\"item_id\"></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 42%;'></td>\n"
            s += "\t</tr>\n"
        end
        return s
    end
end
