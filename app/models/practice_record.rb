class PracticeRecord < ApplicationRecord
  belongs_to :user
  belongs_to :word_list

  MODES = [nil, "recall", "writing"].freeze
  MAX_MISSED = 20

  validates :time_ms, numericality: { only_integer: true, greater_than: 0 }
  validates :mistakes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :word_count, numericality: { only_integer: true, greater_than: 0 }
  validates :mode, inclusion: { in: MODES }
  validate :missed_shape
  validate :writing_needs_a_marked_list

  before_validation { self.practiced_at ||= Time.current }

  scope :recent, -> { order(practiced_at: :desc, id: :desc) }

  # Accuracy first, then time: rank 1 is the best every screen shows.
  def self.ranked(records) = records.sort_by { |record| [-record.accuracy, record.time_ms, record.practiced_at] }

  def seconds = time_ms / 1000.0
  def seconds_per_word = seconds / word_count
  def recall? = mode == "recall"
  def writing? = mode == "writing"
  def mode_label = I18n.t(mode || "normal", scope: "modes")
  def device_label
    return I18n.t("devices.unrecorded") if device_key.nil?
    device_key == Device::DEFAULT_KEY ? I18n.t("design.records.format.default_device") : device_name
  end

  # How this run compares with the list's other runs of the same mode at the same word count.
  def comparison
    ranked = PracticeRecord.ranked(word_list.practice_records.select { |r| r.mode == mode && r.word_count == word_count })
    previous = ranked.find { |r| r.id != id }
    rank = ranked.index(self).to_i + 1
    return { rank:, kind: :first } unless previous
    return { rank:, kind: :best, difference: seconds - previous.seconds } if rank == 1
    { rank:, kind: :behind, best: ranked.first }
  end

  private
    def writing_needs_a_marked_list
      errors.add(:mode, :inclusion) if writing? && !word_list&.writing?
    end

    def missed_shape
      valid = missed.is_a?(Array) && missed.size <= MAX_MISSED && missed.all? { |item|
        item.is_a?(Hash) && item["word"].is_a?(String) && item["word"].present? && item["count"].is_a?(Integer) && item["count"] >= 1
      }
      errors.add(:missed, "is invalid") unless valid
    end
end
