# frozen_string_literal: true

require_relative 'persistent_document'

class Specification < PersistentDocument
  attr_accessor :dictionary, :todo_blocks, :wrong_links_hash, :items_with_uplinks_number, :items_with_downlinks_number,
                :items_with_coverage_number, :duplicated_ids_number, :duplicates_list, :last_used_id,
                :last_used_id_number, :color

  def initialize(fele_path)
    super
    @dictionary = {}
    @duplicates_list = []
    @todo_blocks = []
    @wrong_links_hash = {}

    @items_with_uplinks_number = 0
    @items_with_downlinks_number = 0
    @items_with_coverage_number = 0
    @duplicated_ids_number = 0
    @last_used_id = ''
    @last_used_id_number = 0

    @color = 'bbb'

    @id = File.basename(fele_path, File.extname(fele_path)).downcase
  end

  def to_console
    puts ''
    puts "\e[33mSpecification: #{@title}\e[0m"
    puts '-' * 53
    puts '| Number of Controlled Items           | %10d |' % @controlled_items.length
    puts format('| Number of Items w/ Up-links          | %10d |', @items_with_uplinks_number)
    puts format('| Number of Items w/ Down-links        | %10d |', @items_with_downlinks_number)

    # coverage
    if @controlled_items.length.positive? && (@controlled_items.length == @items_with_coverage_number)
      puts format("| Number of Items w/ Test Coverage     |\e[1m\e[32m %10d \e[0m|", @items_with_coverage_number)
    else
      puts format('| Number of Items w/ Test Coverage     | %10d |', @items_with_coverage_number)
    end

    # duplicates
    if @duplicated_ids_number.positive?
      puts format("| Duplicated Item Ids found            |\e[1m\e[31m %10d \e[0m|", @duplicated_ids_number)
    else
      puts format('| Duplicated Item Ids found            | %10d |', @duplicated_ids_number)
    end

    puts format("| Last used Item Id                    |\e[1m\e[37m %10s \e[0m|", @last_used_id)
    puts '-' * 53
  end

  def to_html(nav_pane, output_file_path)
    html_rows = []

    html_rows.append('')

    @items.each do |item|
      a = item.to_html
      html_rows.append a
    end

    save_html_to_file(html_rows, nav_pane, output_file_path)
  end
end
