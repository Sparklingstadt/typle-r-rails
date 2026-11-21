# One list's ranking on ベスト記録 (typle-r's listRanking): its records of one mode, on one device, ranked by accuracy or
# speed. Rank 1 in accuracy order is the same best every other screen shows (WordList#best).
class ListRanking
  TOP = 5
  IMPROVED_DAYS = 7
  TREND_POINTS = 20
  RECENT_RUNS = 5
  ORDERS = %w[accuracy speed].freeze
  NO_DEVICE = "none"

  attr_reader :list, :records, :ranked, :others, :best, :last_practiced

  def self.matches_device?(record, device)
    device.nil? || (device == NO_DEVICE ? record.device_key.nil? : record.device_key == device)
  end

  def self.rank(records, order)
    return PracticeRecord.ranked(records) unless order == "speed"
    records.sort_by { |record| [record.time_ms, -record.accuracy, record.practiced_at] }
  end

  def initialize(list, mode: nil, device: nil, order: "accuracy", include_others: false, now: Time.current)
    @list, @now = list, now
    @records = list.practice_records.select { |record| record.mode == mode && self.class.matches_device?(record, device) }
    @others = @records.reject { |record| record.word_count == list.words.size }
    @include_others = include_others
    @ranked = self.class.rank(include_others || fallback? ? @records : @records - @others, order)
    @best = @ranked.first
    @last_practiced = @records.map(&:practiced_at).max
  end

  def practised? = ranked.any?

  # Only runs at another word count exist, so they are ranked anyway.
  def fallback? = others.any? && others.size == records.size

  def mixed? = fallback? || @include_others

  # The other word counts and how many runs each has, the largest count first (old runs without one never happen here).
  def other_counts = others.group_by(&:word_count).map { |word_count, items| [word_count, items.size] }.sort_by { |count, _| -count }

  def improved?
    return false unless best
    @now - best.practiced_at < IMPROVED_DAYS.days && ranked.any? { |record| record.practiced_at < best.practiced_at }
  end

  # The latest runs, next to the best: where practice is now.
  def recent = by_date.last(RECENT_RUNS)
  def recent_seconds = recent.sum(&:seconds) / recent.size
  def recent_accuracy = recent.sum(&:accuracy) / recent.size
  def trend = by_date.last(TREND_POINTS)

  private
    def by_date = @by_date ||= ranked.sort_by(&:practiced_at)
end
