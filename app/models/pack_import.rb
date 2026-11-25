require "csv"

# A file chosen to import on 単語リスト, made into a new pack of the user's: typle-r's pack file (JSON, PackFile), or a
# CSV of words, whose pack and list are named after the file.
module PackImport
  # typle-r reads files up to 1 MiB.
  MAX_SIZE = 1.megabyte
  # The columns of typle-r's CSV header, in any order ("anotation" is read as "annotation", as typle-r reads it).
  COLUMNS = %w[display input annotation input_type].freeze

  class TooLarge < StandardError; end
  class NotUtf8 < StandardError; end

  module_function

  # `file` is an upload (read, size, original_filename). Raises TooLarge, NotUtf8, PackFile::Unreadable, or
  # ActiveRecord::RecordInvalid when the words are not a list typle-r saves.
  def call(user, file, default_name:)
    raise TooLarge if file.size > MAX_SIZE
    filename = file.original_filename.to_s
    text = file.read.force_encoding("UTF-8").delete_prefix("﻿")
    return PackFile.import(user, text) if filename.end_with?(".json") || text.lstrip.start_with?("{")

    raise NotUtf8 unless text.valid_encoding?
    name = File.basename(filename, ".*").presence || default_name
    pack = user.packs.new(name:)
    list = pack.word_lists.new(user:, name:)
    rows = header_rows(text)
    rows ? list.words_rows = rows : list.words_text = text
    Pack.transaction do
      pack.save!
      list.save!
    end
    pack
  end

  # The rows of a CSV with typle-r's header (input and display among its columns), or nil for a file without one, whose
  # lines are display, input, annotation (WordList#words_text=). Empty lines are left out.
  def header_rows(text)
    rows = CSV.parse(text) rescue nil
    header = rows&.first&.map { |cell| cell.to_s.strip.downcase.sub(/\Aanotation\z/, "annotation") }
    return unless header&.include?("input") && header.include?("display")
    rows.drop(1).reject { |cells| cells.compact_blank.empty? }.map { |cells| header.zip(cells).to_h.slice(*COLUMNS) }
  end
end
