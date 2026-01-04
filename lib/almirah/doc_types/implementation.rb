require_relative 'base_document'

class Implementation < BaseDocument
    attr_accessor :top_doc, :bottom_doc, :items, :is_agregated, :traced_items

    def initialize(top_doc)
        super()
        @top_doc = top_doc

        @is_agregated = true
        @traced_items = {}

        @id = if @is_agregated
                top_doc.id + '-sources'
              else
                top_doc.id + '-' + bottom_doc.id
              end

        @title = 'Implementation Matrix: ' + @id
    end

    def to_console
        puts "\e[35m" + 'Implementation: ' + @id + "\e[0m"
    end

    def to_html(nav_pane, output_file_path)
        html_rows = []

        html_rows.append('')
        s = "<h1>#{@title}</h1>\n"
        s += "<table class=\"controlled\">\n"
        s += "\t<thead>"
        s += "\t\t<th>#</th>"
        s += "\t\t<th style='font-weight: bold;'>#{@top_doc.title}</th>"
        s += "\t\t<th>#</th>"
        s += "\t\t<th style='font-weight: bold;'>Repository</th>"
        s += "\t\t<th style='font-weight: bold;'>File Name</th>"
        s += "\t\t<th style='font-weight: bold;'>Comment</th>"
        s += "\t</thead>\n"
        html_rows.append s

        sorted_items = @top_doc.controlled_items.sort_by { |w| w.id }

        sorted_items.each do |top_item|
            row = render_table_row top_item
            html_rows.append row
        end
        html_rows.append "</table>\n"

        save_html_to_file(html_rows, nav_pane, output_file_path)
    end

    def render_table_row(top_item)
        s = ''
        top_f_text = top_item.format_string(top_item.text)
        id_color = ''

        if top_item.source_code_links && top_item.source_code_links.length.positive?

            top_item_rendered = false

            top_item.source_code_links.each do |bottom_item|
                id_color = "style='background-color: #cff4d2;'"
                bottom_f_text = bottom_item.format_string(bottom_item.text)
                file_name = bottom_item.parent_doc.id
                repository = bottom_item.parent_doc.repository

                p = bottom_item.parent_doc.html_file_path.split('/build/source_files/').last
                html_source_file_relative_path = "./../../source_files/#{p}"

                s += "\t<tr>\n"
                s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 28%;'>#{top_f_text}</td>\n"
                s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"#{html_source_file_relative_path}##{bottom_item.id}\" class=\"external\">#{bottom_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 16%;'>#{repository}</td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 16%;'>#{file_name}</td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 28%;'>#{bottom_f_text}</td>\n"
                s += "\t</tr>\n"
                top_item_rendered = true
                @traced_items[top_item.id.to_s.downcase] = top_item
            end
            unless top_item_rendered
                s += "\t<tr>\n"
                s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 28%;'>#{top_f_text}</td>\n"
                s += "\t\t<td class=\"item_id\"></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 28%;'></td>\n"
                s += "\t</tr>\n"
            end
        else
            s += "\t<tr>\n"
            s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 28%;'>#{top_f_text}</td>\n"
            s += "\t\t<td class=\"item_id\"></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 28%;'></td>\n"
            s += "\t</tr>\n"
        end
        s
    end
end
