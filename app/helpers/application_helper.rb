module ApplicationHelper
  def nav_link(label, path)
    current = current_page?(path)
    link_to label, path, class: ["nav-link", ("current" if current)], aria: { current: (current ? "page" : nil) }
  end

  # Seconds with two decimals; a minute or more as minutes and seconds, as in typle-r.
  def format_seconds(seconds)
    hundredths = (seconds * 100).round
    return t("format.seconds", value: format("%.2f", hundredths / 100.0)) if hundredths < 6000
    t("format.minutes_seconds", minutes: hundredths / 6000, seconds: format("%05.2f", (hundredths % 6000) / 100.0))
  end

  # A field's first error as typle-r words it: its own messages (duplicate names) stand alone, Rails' name the field.
  def field_error(record, attribute)
    error = record.errors.where(attribute).first
    error && (error.type == :duplicate ? error.message : error.full_message)
  end

  # typle-r's formatAccuracy: one decimal place, written as JavaScript writes the number (100%, 97.7%).
  def format_accuracy(accuracy) = accuracy.nil? ? "—" : "#{accuracy_number(accuracy)}%"

  def accuracy_number(accuracy)
    rounded = accuracy.to_f.round(1)
    rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s
  end

  def format_date(time) = l(time, format: :short_date_time)

  def format_duration(seconds)
    minutes = (seconds / 60).round
    minutes >= 60 ? t("format.hours_minutes", hours: minutes / 60, minutes: minutes % 60) : t("format.minutes", count: minutes)
  end

  def change_badge(now, before)
    diff = now - before
    return tag.span("±0", class: "change") if diff.zero?
    tag.span(diff.positive? ? "+#{diff.round}" : diff.round.to_s, class: ["change", diff.positive? ? "up" : "down"])
  end

  # The words the practice screens' scripts show, in the reader's language.
  def practice_messages
    %w[time accuracy mistakes seconds missed_words weak_done not_saved save_failed read_as reading pad_loading pad_failed]
      .to_h { |key| [key.camelize(:lower), t("practice.messages.#{key}")] }
  end

  def writing_language_name(code) = t("languages.#{code}")
end
