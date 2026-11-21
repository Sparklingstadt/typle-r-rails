# The few typle-r messages whose ICU form carries more than one plural or a select (config/locales/typle/icu.*.yml):
# {name}, {n, plural, =0 {…} one {…} few {…} many {…} other {…}} with #, {n, select, a {…} other {…}} and
# {n, selectordinal, …}, nested, as next-intl reads them.
module IcuMessage
  module_function

  def format(text, values, locale = I18n.locale)
    out = +""
    i = 0
    while i < text.length
      char = text[i]
      if char == "{"
        close = matching(text, i)
        out << argument(text[(i + 1)...close], values, locale)
        i = close + 1
      else
        out << char
        i += 1
      end
    end
    out
  end

  def matching(text, open)
    depth = 0
    (open...text.length).each do |i|
      depth += 1 if text[i] == "{"
      depth -= 1 if text[i] == "}"
      return i if depth.zero?
    end
    raise ArgumentError, "unbalanced braces in #{text}"
  end

  def argument(body, values, locale)
    name, kind, rest = body.split(",", 3).map(&:strip)
    value = values[name.to_sym]
    return value.to_s if kind.nil?
    options = choices(rest)
    case kind
    when "select" then format(options.fetch(value.to_s) { options.fetch("other", "") }, values, locale)
    when "plural", "selectordinal"
      number = value.to_i
      category = kind == "plural" ? plural(number, locale) : ordinal(number, locale)
      chosen = options["=#{number}"] || options[category.to_s] || options["other"] || ""
      # # is this plural's number, outside the arguments nested in it (they have their own).
      format(top_level_hash(chosen, number), values, locale)
    else value.to_s
    end
  end

  def top_level_hash(text, number)
    depth = 0
    text.each_char.map { |char|
      depth += 1 if char == "{"
      depth -= 1 if char == "}"
      char == "#" && depth.zero? ? number.to_s : char
    }.join
  end

  # "one {…} other {…}" as { "one" => "…", "other" => "…" }.
  def choices(text)
    result = {}
    i = 0
    while i < text.length
      i += 1 while i < text.length && text[i].match?(/\s/)
      break if i >= text.length
      start = i
      i += 1 until text[i] == "{"
      key = text[start...i].strip
      close = matching(text, i)
      result[key] = text[(i + 1)...close]
      i = close + 1
    end
    result
  end

  def plural(number, locale)
    rule = I18n.t(:"i18n.plural.rule", locale:, resolve: false)
    rule.respond_to?(:call) ? rule.call(number) : (number == 1 ? :one : :other)
  end

  # English ordinals (1st, 2nd, 3rd, 4th); French has only "premier"; the other languages have no forms.
  def ordinal(number, locale)
    case locale.to_s
    when "en"
      return :few if number % 10 == 3 && number % 100 != 13
      return :two if number % 10 == 2 && number % 100 != 12
      return :one if number % 10 == 1 && number % 100 != 11
      :other
    when "fr" then number == 1 ? :one : :other
    else :other
    end
  end
end
