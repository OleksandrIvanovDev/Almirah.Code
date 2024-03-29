require_relative "paragraph"

class ControlledParagraph < Paragraph

    attr_accessor :id
    attr_accessor :up_link_ids
    attr_accessor :down_links
    attr_accessor :coverage_links

    def initialize(text, id)
        @text = text.strip
        @id = id
        @up_link_ids = nil
        @down_links = nil
        @coverage_links = nil
    end

    def to_html
        s = ''
        unless @@htmlTableRenderInProgress                    
            s += "<table class=\"controlled\">\n"
            s += "\t<thead> <th>#</th> <th></th> <th>UL</th> <th>DL</th> <th>COV</th> </thead>\n"
            @@htmlTableRenderInProgress = true
        end
        f_text = format_string(@text)
        s += "\t<tr>\n"
        s += "\t\t<td class=\"item_id\"> <a name=\"#{@id}\" id=\"#{@id}\" href=\"##{@id}\">#{@id}</a></td>\n"
        s += "\t\t<td class=\"item_text\">#{f_text}</td>\n"

        if @up_link_ids
            if @up_link_ids.length == 1
                if tmp = /^([a-zA-Z]+)[-]\d+/.match(@up_link_ids[0])
                    up_link_doc_name = tmp[1].downcase
                end
                s += "\t\t<td class=\"item_id\"><a href=\"./../#{up_link_doc_name}/#{up_link_doc_name}.html##{@up_link_ids[0]}\" class=\"external\">#{@up_link_ids[0]}</a></td>\n"
            else
                s += "\t\t<td class=\"item_id\">"
                s += "<div id=\"DL_#{@id}\" style=\"display: block;\">"
                s += "<a  href=\"#\" onclick=\"downlink_OnClick(this.parentElement); return false;\" class=\"external\">#{@up_link_ids.length}</a>"
                s += "</div>"
                s += "<div id=\"DLS_#{@id}\" style=\"display: none;\">"
                @up_link_ids.each do |lnk|
                    if tmp = /^([a-zA-Z]+)[-]\d+/.match(lnk)
                        up_link_doc_name = tmp[1].downcase
                    end
                    s += "\t\t\t<a href=\"./../#{up_link_doc_name}/#{up_link_doc_name}.html##{lnk}\" class=\"external\">#{lnk}</a>\n<br>"
                end
                s += "</div>"
                s += "</td>\n"
            end
        else
            s += "\t\t<td class=\"item_id\"></td>\n"
        end

        if @down_links
            if tmp = /^([a-zA-Z]+)[-]\d+/.match(@down_links[0].id)    # guessing that all the links refer to one document
                down_link_doc_name = tmp[1].downcase
            end
            if @down_links.length == 1
                s += "\t\t<td class=\"item_id\"><a href=\"./../#{down_link_doc_name}/#{down_link_doc_name}.html##{@down_links[0].id}\" class=\"external\">#{@down_links[0].id}</a></td>\n"
            else
                s += "\t\t<td class=\"item_id\">"
                s += "<div id=\"DL_#{@id}\" style=\"display: block;\">"
                s += "<a  href=\"#\" onclick=\"downlink_OnClick(this.parentElement); return false;\" class=\"external\">#{@down_links.length}</a>"
                s += "</div>"
                s += "<div id=\"DLS_#{@id}\" style=\"display: none;\">"
                @down_links.each do |lnk|
                    s += "\t\t\t<a href=\"./../#{lnk.parent_doc.id}/#{lnk.parent_doc.id}.html##{lnk.id}\" class=\"external\">#{lnk.id}</a>\n<br>"
                end
                s += "</div>"
                s += "</td>\n"
            end
        else
            s += "\t\t<td class=\"item_id\"></td>\n"
        end

        if @coverage_links
            if tmp = /^(.+)[.]\d+/.match(@coverage_links[0].id)    # guessing that all the links refer to one document
                cov_link_doc_name = tmp[1].downcase
            end
            s += "\t\t<td class=\"item_id\"><a href=\"./../../tests/protocols/#{cov_link_doc_name}/#{cov_link_doc_name}.html\" class=\"external\">#{@coverage_links.length}</a></td>\n"
        else
            s += "\t\t<td class=\"item_id\"></td>\n"
        end
        s += "\t</tr>\n"
        return s
    end 

end