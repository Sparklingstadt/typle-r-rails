# typle-r's sharedResult: a practice result someone shared on X, carried whole in the query of /result. Nothing is
# stored, so every value is checked, and a link with anything missing or out of range shows nothing.
class SharedResult < Data.define(:name, :time, :accuracy, :speed, :words, :mode)
  MODES = %w[normal recall writing].freeze
  MAX_NAME = 60
  MAX_TIME = 36_000
  MAX_SPEED = 5000
  MAX_WORDS = 10_000

  def self.from_query(query)
    name = query[:n].to_s.gsub(/\s+/, " ").strip.chars.first(MAX_NAME).join
    time = number(query[:t], MAX_TIME, integer: false)
    accuracy = number(query[:a], 100, integer: true)
    words = number(query[:w], MAX_WORDS, integer: true)
    speed = query[:s].nil? ? nil : number(query[:s], MAX_SPEED, integer: true)
    mode = (query[:m] || "normal").to_s
    # A time of 0 is a real run: one character can take under the 0.01 s the link keeps.
    return if name.empty? || time.nil? || accuracy.nil? || words.nil? || words < 1 || !mode.in?(MODES)
    return if !query[:s].nil? && speed.nil?
    new(name:, time: (time * 100).round / 100.0, accuracy:, speed:, words:, mode:)
  end

  def self.number(value, max, integer:)
    text = value.to_s
    return unless text.match?(/\A\d+(\.\d+)?\z/)
    parsed = text.to_f
    return if parsed > max || (integer && parsed != parsed.floor)
    integer ? parsed.to_i : parsed
  end
end
