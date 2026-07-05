require_relative 'base_document'

class Traceability < BaseDocument
  attr_accessor :top_doc, :bottom_doc, :items, :is_agregated, :traced_items

  def initialize(top_doc, bottom_doc)
    super()
    @top_doc = top_doc
    @bottom_doc = bottom_doc
    @is_agregated = if bottom_doc
                      false
                    else
                      true
                    end
    @traced_items = {}

    @id = if @is_agregated
            top_doc.id + '-all'
          else
            top_doc.id + '-' + bottom_doc.id
          end

    @title = 'Traceability Matrix: ' + @id
  end

  def to_console
    puts "\e[35m" + 'Traceability: ' + @id + "\e[0m"
  end

  def to_html(nav_pane, output_file_path)
    html_rows = []

    html_rows.append('')
    s = "<h1>#{@title}</h1>\n"
    s += "<table class=\"controlled\">\n"
    s += "\t<thead> <th>#</th> <th style='font-weight: bold;'>#{@top_doc.title}</th> "
    s += if @bottom_doc
           "<th>#</th> <th style='font-weight: bold;'>#{@bottom_doc.title}</th> "
         else
           "<th>#</th> <th style='font-weight: bold;'>All References</th> "
         end
    s += "<th style='font-weight: bold;'>Document Section</th>"
    s += "</thead>\n"
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

    if top_item.down_links

      if @is_agregated

        top_item_rendered = false

        top_item.down_links.each do |bottom_item|
          id_color = "style='background-color: ##{bottom_item.parent_doc.color};'"
          bottom_f_text = bottom_item.format_string(bottom_item.text)
          document_section = bottom_item.parent_heading.get_section_info_html
          s += "\t<tr>\n"
          s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{top_f_text}</td>\n"
          s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"./../#{bottom_item.parent_doc.id}/#{bottom_item.parent_doc.id}.html##{bottom_item.id}\" class=\"external\">#{bottom_item.id}</a></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{bottom_f_text}</td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 16%;'>#{document_section}</td>\n"
          s += "\t</tr>\n"
          top_item_rendered = true
          @traced_items[top_item.id.to_s.downcase] = top_item
        end
        unless top_item_rendered
          s += "\t<tr>\n"
          s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{top_f_text}</td>\n"
          s += "\t\t<td class=\"item_id\"></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
          s += "\t</tr>\n"
        end

      else
        top_item_rendered = false
        top_item.down_links.each do |bottom_item|
          id_color = ''

          next unless bottom_item.parent_doc.id == @bottom_doc.id

          bottom_f_text = bottom_item.format_string(bottom_item.text)
          document_section = bottom_item.parent_heading.get_section_info_html

          s += "\t<tr>\n"
          s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{top_f_text}</td>\n"
          s += "\t\t<td class=\"item_id\"><a href=\"./../#{bottom_item.parent_doc.id}/#{bottom_item.parent_doc.id}.html##{bottom_item.id}\" class=\"external\">#{bottom_item.id}</a></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{bottom_f_text}</td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 16%;'>#{document_section}</td>\n"
          s += "\t</tr>\n"
          top_item_rendered = true
          @traced_items[top_item.id.to_s.downcase] = top_item
        end
        unless top_item_rendered
          s += "\t<tr>\n"
          s += "\t\t<td class=\"item_id\" #{id_color}><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{top_f_text}</td>\n"
          s += "\t\t<td class=\"item_id\"></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 34%;'></td>\n"
          s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
          s += "\t</tr>\n"
        end
      end
    else
      s += "\t<tr>\n"
      s += "\t\t<td class=\"item_id\"><a href=\"./../#{top_item.parent_doc.id}/#{top_item.parent_doc.id}.html##{top_item.id}\" class=\"external\">#{top_item.id}</a></td>\n"
      s += "\t\t<td class=\"item_text\" style='width: 34%;'>#{top_f_text}</td>\n"
      s += "\t\t<td class=\"item_id\"></td>\n"
      s += "\t\t<td class=\"item_text\" style='width: 34%;'></td>\n"
      s += "\t\t<td class=\"item_text\" style='width: 16%;'></td>\n"
      s += "\t</tr>\n"
    end
    s
  end
end
