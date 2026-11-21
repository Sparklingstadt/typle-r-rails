# A sort key close to typle-r's Intl.Collator(locale, { numeric: true }) for names: case and width do not count,
# hiragana and katakana sort together, and scripts come in ICU's order (symbols, digits, Latin, Greek, Cyrillic, kana,
# then kanji and the rest). Runs of digits compare as numbers.
module Collation
  module_function

  def key(name)
    text = String.new(name.to_s, encoding: Encoding::UTF_8).scrub.unicode_normalize(:nfkc).downcase.tr("ァ-ヶ", "ぁ-ゖ")
    text.scan(/\d+|./m).map do |part|
      next [1, part.to_i, ""] if part.match?(/\A\d+\z/)
      [rank(part), 0, part]
    end
  end

  def rank(char)
    case char
    when /\p{Latin}/ then 2
    when /\p{Greek}/ then 3
    when /\p{Cyrillic}/ then 4
    when /\p{Hiragana}|ー/ then 5
    when /\p{Han}/ then 6
    when /[\p{L}\p{N}]/ then 7
    else 0
    end
  end
end
