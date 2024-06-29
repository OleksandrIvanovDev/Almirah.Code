require_relative 'controlled_table_row'
require_relative 'text_line'

class ControlledTableColumn < TextLine # rubocop:disable Style/Documentation
  attr_accessor :text

  def initialize(text) # rubocop:disable Lint/MissingSuper
    @text = text.strip
  end

  def to_html
    f_text = format_string(@text)
    "\t\t<td>#{f_text}</td>\n\r"
  end
end

class RegualrColumn < ControlledTableColumn
end

class TestStepNumberColumn < ControlledTableColumn # rubocop:disable Style/Documentation
  attr_accessor :step_number, :row_id

  def initialize(text)
    super
    @step_number = text.to_i
    @row_id = ''
  end

  def to_html
    "\t\t<td style=\"text-align: center;\"><a name=\"#{@row_id}\" id=\"#{@row_id}\" \
        href=\"##{@row_id}\">#{@text}</a></td>\n\r"
  end
end

class TestStepResultColumn < ControlledTableColumn # rubocop:disable Style/Documentation
  def to_html
    f_text = format_string(@text)
    case @text.downcase
    when 'pass'
      "\t\t<td style=\"background-color: #cfc;\">#{f_text}</td>\n\r"
    when 'fail'
      "\t\t<td style=\"background-color: #fcc;\">#{f_text}</td>\n\r"
    else
      "\t\t<td>#{f_text}</td>\n\r"
    end
  end
end

class TestStepReferenceColumn < ControlledTableColumn # rubocop:disable Style/Documentation
  attr_accessor :up_link_ids, :up_link_doc_ids, :parent_row

  def initialize(parent_row, text)
    super(text)
    @up_link_ids = nil
    @up_link_doc_ids = {}
    @parent_row = parent_row

    up_links = nil

    # check if it contains the uplink (one or many)
    first_pos = text.length # for trailing commas
    tmp = text.scan(/(>\[(?>[^\[\]]|\g<0>)*\])/) # >[SRS-001], >[SYS-002]
    unless tmp.empty?
      up_links = []
      tmp.each do |ul|
        lnk = ul[0]
        # do not add links for the self document
        doc_id = /([a-zA-Z]+)-\d+/.match(lnk) # SRS
        up_links << lnk.upcase if doc_id # (doc_id) and (doc_id[1].downcase != doc.id.downcase)
        # try to find the real end of text
        pos = text.index(lnk)
        first_pos = pos if pos < first_pos
        # remove uplink from text
        text = text.split(lnk, 1).join('')
      end
      # remove trailing commas and spaces
      if text.length > first_pos
        first_pos -= 1
        text = text[0..first_pos].strip
      end
    end

    if up_links # rubocop:disable Style/GuardClause
      up_links.uniq! # remove duplicates
      # doc.items_with_uplinks_number += 1 # for statistics
      up_links.each do |ul|
        next unless tmp = />\[(\S*)\]$/.match(ul) # >[SRS-001]

        up_link_id = tmp[1]

        @up_link_ids ||= []

        @up_link_ids.append(up_link_id)

        if tmp = /^([a-zA-Z]+)-\d+/.match(up_link_id) # SRS
          @up_link_doc_ids[tmp[1].downcase.to_s] = tmp[1].downcase # multiple documents could be up-linked
        end
      end
    end
  end

  def to_html # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    s = ''
    if @up_link_ids
      if @up_link_ids.length == 1
        if tmp = /^([a-zA-Z]+)-\d+/.match(@up_link_ids[0])
          up_link_doc_name = tmp[1].downcase
        end
        s += "\t\t<td class=\"item_id\" style=\"text-align: center;\">\
                    <a href=\"./../../../specifications/#{up_link_doc_name}/#{up_link_doc_name}.html##{@up_link_ids[0]}\" \
                    class=\"external\" title=\"Linked to\">#{@up_link_ids[0]}</a></td>\n"
      else
        s += "\t\t<td class=\"item_id\" style=\"text-align: center;\">"
        s += "<div id=\"COV_#{@parent_row.id}\" style=\"display: block;\">"
        s += "<a  href=\"#\" onclick=\"coverageLink_OnClick(this.parentElement); return false;\" \
                    class=\"external\" title=\"Number of verified items\">#{@up_link_ids.length}</a>"
        s += '</div>'
        s += "<div id=\"COVS_#{@parent_row.id}\" style=\"display: none;\">"
        @up_link_ids.each do |lnk|
          if tmp = /^([a-zA-Z]+)-\d+/.match(lnk)
            up_link_doc_name = tmp[1].downcase
          end
          s += "\t\t\t<a href=\"./../../../specifications/#{up_link_doc_name}/#{up_link_doc_name}.html##{lnk}\" \
                    class=\"external\" title=\"Verifies\">#{lnk}</a>\n<br>"
        end
        s += '</div>'
        s += "</td>\n"
      end
    else
      "\t\t<td style=\"text-align: center;\"></td>\n\r"
    end
  end
end

class ControlledTable < DocItem # rubocop:disable Style/Documentation
  attr_accessor :column_names, :rows, :is_separator_detected

  def initialize(doc, markdown_table) # rubocop:disable Lint/MissingSuper
    @parent_doc = doc
    @parent_heading = doc.headings[-1]

    @column_names = markdown_table.column_names
    @is_separator_detected = markdown_table.is_separator_detected
    # copy and re-format existing rows
    @rows = []

    markdown_table.rows.each do |r|
      @rows.append(format_columns(r))
    end
  end

  def add_row(row)
    columns = row.split('|')

    @rows.append(format_columns(columns))

    true
  end

  def format_columns(columns) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    new_row = ControlledTableRow.new
    new_row.parent_doc = @parent_doc

    columns.each_with_index do |element, index|
      if index.zero? # it is expected that test step id is placed in the first columl

        col = TestStepNumberColumn.new element
        new_row.columns.append col
        new_row.id = "#{@parent_doc.id}.#{col.text}"
        col.row_id = new_row.id

      elsif index + 1 == columns.length # it is expected that a link is placed to the last column only

        col = TestStepReferenceColumn.new(new_row, element)
        new_row.columns << col
        # save uplink key but do not rewrite
        unless col.up_link_doc_ids.empty?
          col.up_link_doc_ids.each do |key, value|
            @parent_doc.up_link_docs[key] = value

            # save reference to the test step
            new_row.up_link_ids = col.up_link_ids
            @parent_doc.controlled_items.append new_row
          end
        end

      elsif index + 2 == columns.length # it is expected that test step result is placed to the pre-last column only

        col = TestStepResultColumn.new element
        new_row.columns.append col

      else
        col = RegualrColumn.new element
        new_row.columns.append col
      end
    end
    new_row
  end

  def to_html # rubocop:disable Metrics/MethodLength
    s = ''
    if @@html_table_render_in_progress
      s += "</table>\n"
      @@html_table_render_in_progress = false # rubocop:disable Style/ClassVars
    end

    s += "<table class=\"markdown_table\">\n"
    s += "\t<thead>"

    @column_names.each do |h|
      s += " <th>#{h}</th>"
    end

    s += " </thead>\n"

    @rows.each do |row|
      s += row.to_html
    end

    s += "</table>\n"

    s
  end
end
