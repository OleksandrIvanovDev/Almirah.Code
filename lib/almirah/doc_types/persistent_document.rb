# frozen_string_literal: true

require_relative 'base_document'

class PersistentDocument < BaseDocument # rubocop:disable Style/Documentation
  attr_accessor :path, :items, :controlled_items, :headings, :up_link_docs

  def initialize(fele_path)
    super()
    @path = fele_path
    @items = []
    @controlled_items = []
    @headings = []
    @up_link_docs = {}
  end
end
