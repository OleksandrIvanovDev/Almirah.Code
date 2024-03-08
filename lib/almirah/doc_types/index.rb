require_relative "base_document"

class Index < BaseDocument

    attr_accessor :items
    attr_accessor :project

    def initialize(project)
        @items = Array.new
        @project = project

        @title = "Document Index"
        @id = "index"
    end

    def to_console
        puts "\e[36m" + "Index: " + @id + "\e[0m"
    end

    def to_html(output_file_path)

        html_rows = Array.new

        html_rows.append('')
        s = "<h1>#{@title}</h1>\n"

        # Specifications
        s = "<h2>Specifications</h2>\n"
        s += "<table class=\"controlled\">\n"
        s += "\t<thead>\n"
        s += "\t\t<th>Title</th>\n"
        s += "\t\t<th>Items</th>\n"
        s += "\t\t<th>Items<br>w/ Uplinks</th>\n"
        s += "\t\t<th>Items<br>w/ Downlinks</th>\n"
        s += "\t\t<th>Covered<br>by Tests</th>\n"
        s += "\t\t<th>Duplicated<br>ids</th>\n"
        s += "\t\t<th>Last Used<br>id</th>\n"
        s += "</thead>\n"
        html_rows.append s

        sorted_items = @project.specifications.sort_by { |w| w.id }

        sorted_items.each do |doc|
            s = "\t<tr>\n"
            s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"./specifications/#{doc.id}/#{doc.id}.html\" class=\"external\">#{doc.title}</a></td>\n"
            s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.controlled_items.length.to_s}</td>\n"
            s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.items_with_uplinks_number.to_s}</td>\n"
            s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.items_with_downlinks_number.to_s}</td>\n"
            s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.items_with_coverage_number.to_s}</td>\n"
            s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.duplicated_ids_number.to_s}</td>\n"
            s += "\t\t<td class=\"item_id\" style='width: 7%;'>#{doc.last_used_id.to_s}</td>\n"
            s += "</tr>\n"
            html_rows.append s
        end
        html_rows.append "</table>\n"

        # Traceability Matrices
        s = "<h2>Traceability Matrices</h2>\n"
        s += "<table class=\"controlled\">\n"
        s += "\t<thead>\n"
        s += "\t\t<th>Title</th>\n"
        s += "\t\t<th>Top Document</th>\n"
        s += "\t\t<th>Bottom Document</th>\n"
        s += "</thead>\n"
        html_rows.append s

        sorted_items = @project.traceability_matrices.sort_by { |w| w.id }

        sorted_items.each do |doc|
            s = "\t<tr>\n"
            s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"./specifications/#{doc.id}/#{doc.id}.html\" class=\"external\">#{doc.title}</a></td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'>#{doc.top_doc.title}</td>\n"
            s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'>#{doc.bottom_doc.title}</td>\n"
            s += "</tr>\n"
            html_rows.append s
        end
        html_rows.append "</table>\n"

        # Coverage Matrices
        if @project.coverage_matrices.length > 0
            s = "<h2>Coverage Matrices</h2>\n"
            s += "<table class=\"controlled\">\n"
            s += "\t<thead>\n"
            s += "\t\t<th>Title</th>\n"
            s += "\t\t<th>Specification Covered</th>\n"
            s += "</thead>\n"
            html_rows.append s

            sorted_items = @project.coverage_matrices.sort_by { |w| w.id }

            sorted_items.each do |doc|
                s = "\t<tr>\n"
                s += "\t\t<td class=\"item_text\" style='padding: 5px;'><a href=\"./specifications/#{doc.id}/#{doc.id}.html\" class=\"external\">#{doc.title}</a></td>\n"
                s += "\t\t<td class=\"item_text\" style='width: 25%; padding: 5px;'>#{doc.top_doc.title}</td>\n"
                s += "</tr>\n"
                html_rows.append s
            end
            html_rows.append "</table>\n"
        end

        self.save_html_to_file(html_rows, nil, output_file_path)
        
    end



end