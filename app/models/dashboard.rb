# The home dashboard of a user: dates and weeks (from Monday) in the app's time zone.
class Dashboard
  WEAK_RUNS = 10
  WEAK_LISTS = 3
  WEAK_WORDS_SHOWN = 6

  WeakList = Data.define(:list, :words, :more)
  WeakWord = Data.define(:word, :runs, :count)

  TREND_POINTS = 20
  STALE_DAYS = 3
  LOW_ACCURACY = 90
  # Averages of the newest runs against the runs before them, as in typle-r's src/lib/dashboard.ts.
  Change = Data.define(:recent, :recent_count, :previous, :previous_count)
  TrendPoint = Data.define(:time, :value)
  Trend = Data.define(:points, :change)
  ListTrend = Data.define(:list, :count, :last_practiced, :speed, :accuracy, :best)
  # A chart's value range and its three gridlines (top, middle, bottom).
  Scale = Data.define(:low, :high, :ticks, :decimals)

  def initialize(user, now: Time.current)
    @user = user
    @now = now
    @records = user.practice_records.includes(word_list: [:words, :pack]).recent.to_a
  end

  attr_reader :records

  def any? = records.any?

  # The list practised last that still has words.
  def continue_list = records.map(&:word_list).find { |list| list.words.any? }

  def week
    this_week = records.select { |r| r.practiced_at >= week_start }
    last_week = records.select { |r| r.practiced_at >= week_start - 1.week && r.practiced_at < @now - 1.week }
    recent = records.select { |r| r.mode.nil? }.first(10)
    {
      runs: this_week.size, runs_before: last_week.size,
      seconds: this_week.sum(&:seconds), seconds_before: last_week.sum(&:seconds),
      accuracy: recent.any? ? (recent.sum(&:accuracy) / recent.size).round(1) : nil,
      streak: streak,
      practiced_today: records.any? { |r| r.practiced_at.to_date == @now.to_date },
      accuracy_count: recent.size,
      accuracy_change: self.class.change(normal_records.map { |r| r.accuracy.to_f }, recent.size, [normal_records.size - recent.size, 10].min)
    }
  end

  def week_start = @now.beginning_of_week(:monday)

  # Normal-mode runs, newest first (recall and handwriting are not compared with them).
  def normal_records = @normal_records ||= records.select { |r| r.mode.nil? && r.word_count.to_i.positive? }

  def last_normal_practice(list) = normal_records.find { |r| r.word_list_id == list.id }&.practiced_at

  # Per list with normal runs, seconds per word and accuracy of its last TREND_POINTS runs, practised last first.
  def list_trends
    normal_records.group_by(&:word_list).map { |list, list_records|
      oldest_first = list_records.reverse
      ListTrend.new(
        list:, count: list_records.size, last_practiced: list_records.first.practiced_at,
        speed: self.class.trend(oldest_first.map { |r| TrendPoint.new(time: r.practiced_at, value: r.seconds_per_word) }),
        accuracy: self.class.trend(oldest_first.map { |r| TrendPoint.new(time: r.practiced_at, value: r.accuracy.to_f) }),
        best: list.best
      )
    }
  end

  def self.change(newest, recent_count, previous_count)
    return if recent_count.zero? || previous_count <= 0
    average = ->(values) { values.sum / values.size }
    Change.new(recent: average.(newest.first(recent_count)), recent_count:,
               previous: average.(newest[recent_count, previous_count]), previous_count:)
  end

  def self.trend(points)
    newest = points.map(&:value).reverse
    recent_count = [5, (newest.size / 2.0).ceil].min
    Trend.new(points: points.last(TREND_POINTS), change: change(newest, recent_count, [5, newest.size - recent_count].min))
  end

  def self.speed_scale(values)
    min, max = values.minmax
    step = nice_step([max - min, max * 0.1, 0.01].max / 2)
    low = tidy((min / step).floor * step)
    while tidy(low + step * 2) < max
      step = nice_step(step * 1.001)
      low = tidy((min / step).floor * step)
    end
    high = tidy(low + step * 2)
    Scale.new(low:, high:, ticks: [high, tidy(low + step), low], decimals: step.to_s.sub(/\.0\z/, "").split(".")[1].to_s.size)
  end

  def self.accuracy_scale(values)
    low = [0, [80, (values.min / 10).floor * 10].min].max
    Scale.new(low:, high: 100, ticks: [100, (low + 100) / 2.0, low], decimals: 0)
  end

  def self.tidy(value) = (value * 1e6).round / 1e6

  def self.nice_step(value)
    power = 10.0**Math.log10(value).floor
    fraction = value / power
    tidy((fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 2.5 ? 2.5 : fraction <= 5 ? 5 : 10) * power)
  end

  # Days in a row with practice, up to today (or up to yesterday when today has none yet).
  def streak
    days = records.map { |r| r.practiced_at.to_date }.to_set
    day = @now.to_date
    day -= 1 unless days.include?(day)
    count = 0
    while days.include?(day)
      count += 1
      day -= 1
    end
    count
  end

  # Per list, the words that went wrong in its last WEAK_RUNS runs after the last weak review, most runs first.
  def weak_lists
    @user.word_lists.includes(:words).filter_map { |list|
      words = self.class.weak_words(list, records.select { |r| r.word_list_id == list.id })
      WeakList.new(list:, words: words.first(WEAK_WORDS_SHOWN), more: [words.size - WEAK_WORDS_SHOWN, 0].max) if words.any?
    }.sort_by { |item| -item.words.size }.first(WEAK_LISTS)
  end

  def self.weak_words(list, list_records)
    runs = list_records.reject(&:writing?).select { |r| list.weak_reviewed_at.nil? || r.practiced_at > list.weak_reviewed_at }.first(WEAK_RUNS)
    missed_sets = runs.map(&:missed)
    missed_sets << list.weak_review_missed if list.weak_reviewed_at && runs.size < WEAK_RUNS
    order = list.words.map(&:input)
    tally = Hash.new { |hash, key| hash[key] = [0, 0] }
    missed_sets.each do |missed|
      missed.each do |item|
        next unless order.include?(item["word"])
        tally[item["word"]][0] += 1
        tally[item["word"]][1] += item["count"]
      end
    end
    tally.map { |word, (runs_count, count)| WeakWord.new(word:, runs: runs_count, count:) }
      .sort_by { |w| [-w.runs, -w.count, order.index(w.word)] }
  end

  # Lists to practise next: never practised, not practised for 3 days, or recent accuracy under 90%.
  def next_lists
    lists = @user.word_lists.includes(:words, :pack).to_a
    by_list = records.select { |r| r.mode.nil? }.group_by(&:word_list_id)
    picks = []
    lists.each { |l| picks << [l, [:never, {}]] unless records.any? { |r| r.word_list_id == l.id } }
    lists.each do |l|
      last = by_list[l.id]&.first
      picks << [l, [:idle, { count: ((@now - last.practiced_at) / 1.day).floor }]] if last && last.practiced_at < @now - 3.days
    end
    lists.each do |l|
      recent = (by_list[l.id] || []).first(5)
      next if recent.empty?
      average = recent.sum(&:accuracy) / recent.size
      picks << [l, [:low_accuracy, { accuracy: average.round(1), count: recent.size }]] if average < LOW_ACCURACY
    end
    picks.uniq { |l, _| l.id }.first(3)
  end
end
