class WordList < ApplicationRecord
  belongs_to :pack
  belongs_to :user
  has_many :words, -> { order(:position, :id) }, dependent: :delete_all, inverse_of: :word_list
  has_many :practice_records, dependent: :delete_all

  # typle-r's limit of words in a list.
  MAX_WORDS = 1000

  WRITING_LANGUAGES = %w[en ja zh-Hans zh-Hant ko fr de es ru cs].freeze
  # Languages the app reads handwriting in itself, with the handwriting pad (public/handwriting).
  PAD_LANGUAGES = %w[ko].freeze

  validates :name, presence: true, length: { maximum: 200 }
  validates :writing_language, inclusion: WRITING_LANGUAGES, allow_nil: true
  normalizes :writing_language, with: ->(value) { value.presence }
  validate :has_words
  validate :name_not_taken
  validate :room_for_own_list, on: :create

  # typle-r's MAX_LISTS: lists of followed packs are not counted.
  MAX_OWN_LISTS = 150

  before_validation { self.user ||= pack&.user }
  before_create { self.position = (pack.word_lists.maximum(:position) || 0) + 1 }

  delegate :editable?, :followed?, to: :pack

  # Gives each list's pack the loaded lists of that pack as its word_lists, so that a list's name, category and tags
  # (which look at the pack's other lists) need no query per pack. `lists` are all of a user's lists, with their packs.
  def self.share_packs(lists)
    siblings = lists.group_by(&:pack_id).transform_values { |items| items.sort_by { |list| [list.position, list.id] } }
    # A pack loaded with a join may be a different object for each of its lists, so each list's own pack gets them.
    lists.each do |list|
      association = list.pack.association(:word_lists)
      association.target = siblings[list.pack_id]
      association.loaded!
    end
    lists
  end

  # typle-r's viewLists: a list is named with its pack (its group) when the pack has two or more lists or the list has a
  # level, and then by its level (levelName) when it has one.
  def grouped? = level.present? || pack.list_count >= 2

  # The pack name with the list's part, as the list is shown outside its pack: "Vimコマンド（2） › 初級".
  def full_name = grouped? ? "#{pack.name} › #{level.presence || name}" : name

  # The pack and the list's own part of its name, as typle-r's practiceName: [nil, name] for a list on its own.
  def name_parts = grouped? ? [pack.name, level.presence || name] : [nil, name]

  # The pack's category and tags are its lists' (typle-r's viewLists); the list's own are kept for a pack without them.
  def category = pack&.read_attribute(:category).presence || self[:category]

  # A pack's tags, or those of a followed official list.
  def tags = pack&.read_attribute(:tags).presence || (origin_list_id ? (OfficialCatalog.find_list(origin_list_id)&.last&.tags || []) : [])

  # Replaces the words with the rows of a text area: one word per line, "表示<TAB>入力<TAB>注釈" or comma-separated.
  # The input defaults to the display when it is left out.
  def words_text=(text)
    rows = text.to_s.each_line.map(&:chomp).reject(&:blank?).map { |line| WordRow.parse(line) }
    @words_text = text
    words.reset
    self.words = rows.each_with_index.map { |(display, input, annotation), index|
      Word.new(display:, input: input.presence || display, annotation: annotation.to_s, position: index)
    }
  end

  # Replaces the words with the rows of the word editor (typle-r's WordRowFields): display, input (the display when left
  # empty), annotation and input type. An empty row is kept, so the list is not saved with it (typle-r's validateList).
  def words_rows=(rows)
    kept = Array(rows).map { |row| row.respond_to?(:to_h) ? row.to_h.symbolize_keys : {} }
    @words_text = nil
    words.reset
    self.words = kept.each_with_index.map { |row, index|
      Word.new(display: row[:display].to_s, input: row[:input].presence || row[:display].to_s, annotation: row[:annotation].to_s,
        input_type: row[:input_type].presence_in(Word::INPUT_TYPES), position: index)
    }
  end

  def words_text = @words_text || words.map { |word| [word.display, word.input, word.annotation].join("\t").sub(/\t+\z/, "") }.join("\n")

  # Records compared for the best: this mode, and only runs at the current word count when there are any
  # (editing a list changes the task). Ranked by accuracy, then time.
  def comparable_records(mode = nil)
    of_mode = practice_records.select { |record| record.mode == mode }
    same = of_mode.select { |record| record.word_count == words.size }
    PracticeRecord.ranked(same.any? ? same : of_mode)
  end

  def best(mode = nil) = comparable_records(mode).first

  def writing? = writing_language.present?

  private
    # listNameDuplicate: the lists of a pack have different names, case aside.
    def name_not_taken
      return if name.blank? || pack.nil?
      key = name.strip.downcase
      errors.add(:name, :duplicate, message: I18n.t("typle.errors.listNameDuplicate")) if pack.word_lists.reject { |list| list.equal?(self) || (id && list.id == id) }.any? { |list| list.name.strip.downcase == key }
    end

    def room_for_own_list
      return if pack.nil? || pack.followed? || user.nil?
      own = user.word_lists.joins(:pack).where(packs: { catalog_id: nil }).count
      errors.add(:base, I18n.t("typle.errors.listLimit", max: MAX_OWN_LISTS)) if own >= MAX_OWN_LISTS
    end

    def has_words
      errors.add(:base, :words_required) if words.empty?
      errors.add(:base, :too_many_words, count: MAX_WORDS) if words.size > MAX_WORDS
      words.each_with_index do |word, index|
        errors.add(:base, :word_fields_required, line: index + 1) if word.display.blank? || word.input.blank?
      end
    end
end
