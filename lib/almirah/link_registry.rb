# frozen_string_literal: true

# Project-wide registry of managed documents, used to resolve cross-document
# links (ADR-186) to their generated output pages. Documents are indexed by
# their id / filename stem (case-insensitive, folder-independent) and, when they
# originate from a source file, by their absolute source path (for native
# Markdown relative links).
class LinkRegistry
  attr_reader :collisions

  def initialize
    @by_id = {}
    @by_source = {}
    @collisions = []
  end

  # Each registered document is expected to already carry an output_rel_path
  # (its generated page, relative to the build root).
  def register(doc)
    register_id(doc.id.to_s.downcase, doc)
    return unless doc.respond_to?(:path) && doc.path

    # Also index by the filename stem so a document resolves by filename, not
    # only by id (SRS-090). For specs/protocols the stem equals the id; for
    # decision records the id is the truncated <letters>-<digits> prefix, so the
    # full stem (e.g. "adr-170-introduce-decision-records") is a distinct alias.
    register_id(File.basename(doc.path, '.*').downcase, doc)
    @by_source[File.expand_path(doc.path)] = doc
  end

  def find_by_id(id)
    @by_id[id.to_s.downcase]
  end

  def find_by_source(source_path)
    @by_source[File.expand_path(source_path)]
  end

  private

  # Adds an id/stem key for a document, recording a collision only when the key
  # already maps to a different document. Registering the same document under
  # both its id and its filename stem is expected and not a collision.
  def register_id(key, doc)
    return if key.empty?

    if @by_id.key?(key) && !@by_id[key].equal?(doc)
      @collisions << key
    else
      @by_id[key] = doc
    end
  end
end
