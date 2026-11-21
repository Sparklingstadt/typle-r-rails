class Pack < ApplicationRecord
  belongs_to :user
  has_many :word_lists, -> { order(:position, :id) }, dependent: :destroy

  # typle-r's MAX_CATEGORY, MAX_TAG and MAX_TAGS.
  MAX_CATEGORY = 50
  MAX_TAG = 50
  MAX_TAGS = 20

  validates :name, presence: true, length: { maximum: 200 }
  validates :category, length: { maximum: MAX_CATEGORY }
  validate :tags_fit
  validate :name_not_taken
  validate :room_to_follow, on: :create, if: :followed?

  # typle-r's MAX_FOLLOWED_PACKS.
  MAX_FOLLOWED = 200

  # normalizeLabels: a trimmed category or none, and the tags trimmed, without blanks or repeats (case aside).
  normalizes :category, with: ->(value) { value.to_s.strip.presence }
  normalizes :tags, with: ->(tags) { Array(tags).map { |tag| tag.to_s.strip }.reject(&:empty?).uniq(&:downcase) }

  before_create { self.position = (user.packs.maximum(:position) || 0) + 1 }

  def followed? = catalog_id.present?
  def editable? = !followed?
  def word_count = word_lists.sum { |list| list.words.size }

  # The category and tags of the pack: its own (typle-r's PackFields), or those its official lists carry.
  def category = self[:category].presence || word_lists.map(&:category).compact_blank.first
  def tags = self[:tags].presence || word_lists.flat_map(&:tags).uniq

  def last_practiced_at = word_lists.flat_map(&:practice_records).map(&:practiced_at).max

  # The text the packs page searches: pack and list names, labels and words (typle-r searches words too).
  def search_text = [name, category, *tags, *word_lists.flat_map { |list| [list.name, list.level, *list.words.map(&:display), *list.words.map(&:input)] }].compact.join("\n").downcase

  private
    # packNameDuplicate: no two packs of a user share a name, case aside.
    def name_not_taken
      return if name.blank? || user.nil?
      key = name.strip.downcase
      errors.add(:name, :duplicate, message: I18n.t("typle.errors.packNameDuplicate")) if user.packs.where.not(id: id).any? { |pack| pack.name.strip.downcase == key }
    end

    def room_to_follow
      errors.add(:base, I18n.t("typle.errors.followLimit", max: MAX_FOLLOWED)) if user && user.packs.where.not(catalog_id: nil).count >= MAX_FOLLOWED
    end

    def tags_fit
      errors.add(:tags, I18n.t("typle.wordLists.editor.tagsFull", max: MAX_TAGS)) if self[:tags].size > MAX_TAGS
      errors.add(:tags, :too_long, count: MAX_TAG) if self[:tags].any? { |tag| tag.length > MAX_TAG }
    end
end
