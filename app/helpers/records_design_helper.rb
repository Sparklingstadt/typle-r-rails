# typle-r's record pieces for 練習記録 and ベスト記録 (src/components/Records, src/components/Rankings), with the formats
# of its useFormat. Text lives under design.records (config/locales/design/records.*.yml).
module RecordsDesignHelper
  LOW_ACCURACY = 90
  # Shared by the column labels and the rows so the numbers line up under their headings (RecordRow's recordColumns).
  RECORDS_COLUMNS = "sm:grid-cols-[3.25rem_minmax(0,1fr)_7rem_4.75rem_5.25rem_3rem_2.5rem] sm:gap-x-4"
  RECORDS_PILL = "inline-flex h-9 shrink-0 items-center rounded-full border bg-muted/60 p-0.5 text-[13px]"
  RECORDS_PILL_ITEM = "inline-flex h-full items-center rounded-full px-3 text-muted-foreground outline-none hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50 aria-checked:bg-background aria-checked:font-medium aria-checked:text-foreground aria-checked:shadow-sm dark:aria-checked:bg-input"
  RECORDS_MENU_ITEM = UiHelper::MENU_INSET_ITEM

  def records_t(key, **options) = t("design.records.#{key}", **options)

  # A message with typle-r's rich-text tags (<rankings>…</rankings>): each tag's chunk goes through the lambda of its name.
  def records_rich(key, tags = {}, **options)
    text = ERB::Util.html_escape(records_t(key, **options)).to_str
    tags.each do |name, render|
      text = text.gsub(%r{&lt;#{name}&gt;(.*?)&lt;/#{name}&gt;}m) { ERB::Util.html_escape(render.(Regexp.last_match(1).html_safe)) }
    end
    text.html_safe
  end

  def records_unit_space = I18n.locale.to_s.start_with?("ja", "zh") ? "" : " "

  # RecordTime: seconds with two decimals, a minute or more as minutes and seconds, the units smaller than the numbers.
  def records_time(seconds, class: nil)
    space = records_unit_space
    spans = records_time_parts(seconds).each_with_index.map { |(value, unit), index|
      tag.span(safe_join([(space if index.positive?), value, space, tag.span(records_t("format.units.#{unit}"), class: "ml-px text-[0.8em] font-normal text-muted-foreground")].compact))
    }
    tag.span(safe_join(spans), class: cn("tabular-nums", binding.local_variable_get(:class)), title: records_t("history.row.seconds", value: format("%.2f", seconds)))
  end

  def records_time_text(seconds)
    space = records_unit_space
    records_time_parts(seconds).map { |value, unit| "#{value}#{space}#{records_t("format.units.#{unit}")}" }.join(space)
  end

  def records_time_parts(seconds)
    hundredths = (seconds * 100).round
    return [[format("%.2f", hundredths / 100.0), "seconds"]] if hundredths < 6000
    [[(hundredths / 6000).to_s, "minutes"], [format("%05.2f", (hundredths % 6000) / 100.0), "seconds"]]
  end

  # Practice time in whole seconds, minutes or hours (format.duration).
  def records_duration(seconds)
    total = seconds.round
    parts = if total < 60 then [[total, "seconds"]]
            elsif total < 3600 then [[total / 60, "minutes"], [total % 60, "seconds"]]
            else [[total / 3600, "hours"], [total % 3600 / 60, "minutes"]]
            end
    space = records_unit_space
    parts.map { |value, unit| "#{value}#{space}#{records_t("format.units.#{unit}")}" }.join(space)
  end

  def records_accuracy(accuracy) = format_accuracy(accuracy)

  def records_date_parts(time) = { year: time.year, month: time.month, day: time.day, month_name: records_t("extra.months").split(",")[time.month - 1] }

  # 9月19日, with the year only when it is not this year.
  def records_date(time, now = Time.current)
    records_t(time.year == now.year ? "extra.month_day" : "extra.year_month_day", **records_date_parts(time))
  end

  # 今日, 昨日 or the date (format.day).
  def records_day(time, now = Time.current)
    case (now.to_date - time.to_date).to_i
    when 0 then records_t("format.today")
    when 1 then records_t("format.yesterday")
    else records_date(time, now)
    end
  end

  def records_today?(time, now = Time.current) = time.to_date == now.to_date

  # The heading of a day: today and yesterday are named before the date with its weekday (useDayHeading).
  def records_day_heading(day, now = Time.current)
    date = records_t("format.date_with_weekday", date: records_date(day, now), weekday: records_t("extra.weekdays").split(",")[day.wday])
    (now.to_date - day.to_date).to_i.in?(0..1) ? records_t("history.day.heading", relative: records_day(day, now), date:) : date
  end

  # typle-r's format.clock (Intl hour and minute, 2-digit): 24 hours, but "02:05 PM" in English and "下午02:05" in
  # Traditional Chinese, as the browser writes them.
  def records_clock(time)
    hour12 = format("%02d", (time.hour % 12).nonzero? || 12)
    case I18n.locale.to_s
    when "en" then "#{hour12}:#{time.strftime("%M")} #{time.hour < 12 ? "AM" : "PM"}"
    when "zh-Hant" then "#{time.hour < 12 ? "上午" : "下午"}#{hour12}:#{time.strftime("%M")}"
    else time.strftime("%H:%M")
    end
  end
  def records_numeric_date(time) = records_t("extra.numeric_date", **records_date_parts(time))
  def records_short_date(time) = records_t("extra.short_date", **records_date_parts(time))

  # The device a record was made on, by name alone, or with its layout (format.deviceName / format.device).
  def records_device_name(record) = record.device_key == Device::DEFAULT_KEY ? records_t("format.default_device") : record.device_name

  def records_device(record)
    return records_t("format.no_device_recorded") if record.device_key.nil?
    record.device_layout.present? ? records_t("format.device_with_layout", name: records_device_name(record), layout: record.device_layout) : records_device_name(record)
  end

  def records_level_name(list) = list.level.presence || list.name

  # BestBadge / RecallBadge / the handwriting badge of a row.
  def records_best_badge
    tag.span(safe_join([icon(:trophy, class: "size-3"), records_t("history.row.best")]), title: records_t("history.row.best_title"),
      class: "inline-flex h-5 shrink-0 items-center gap-1 rounded-full bg-amber-100 px-2 text-xs font-bold text-amber-800 dark:bg-amber-950 dark:text-amber-300")
  end

  def records_mode_badge(record)
    if record.writing?
      tag.span(safe_join([icon("pen-line", class: "size-3"), records_t("history.mode_writing")]), class: "inline-flex h-5 shrink-0 items-center gap-1 rounded-full border px-2 text-xs font-medium")
    elsif record.recall?
      tag.span(records_t("history.recall_badge"), class: "inline-flex h-5 shrink-0 items-center rounded-full bg-sky-100 px-2 text-xs font-bold text-sky-800 dark:bg-sky-950 dark:text-sky-300")
    end
  end

  # FilterMenu: a pill that reads as the current filter and opens the choices, as links, with their record counts.
  # `options` are [value, label, count]; `url` builds the link of a value (nil for all).
  def records_filter_menu(name:, all_label:, value:, options:, url:)
    current = options.find { |option| option[0] == value }
    trigger = cn("inline-flex h-9 max-w-full min-w-0 items-center gap-1.5 rounded-full border bg-background px-3.5 text-sm outline-none hover:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50 aria-expanded:bg-muted dark:bg-input/30",
      current && "border-foreground/25 bg-secondary font-medium dark:bg-secondary")
    choices = [[nil, all_label, options.sum { |option| option[2] }], *options]
    tag.div(class: "relative max-w-full", data: { controller: "dropdown" }) do
      safe_join([
        tag.button(type: "button", class: trigger, data: { dropdown_target: "trigger" }, "aria-label": records_t("history.filter_menu.label", name:, current: current ? current[1] : all_label)) {
          safe_join([tag.span(name, class: "shrink-0 text-muted-foreground"), tag.span(current ? current[1] : records_t("history.filter_menu.all"), class: "truncate"),
                     icon("chevron-down", class: "size-3.5 shrink-0 text-muted-foreground")])
        },
        tag.div(role: "menu", class: cn(UiHelper::MENU_CONTENT, "absolute top-full left-0 mt-1.5 max-h-96 w-72 max-w-[calc(100vw-2rem)] overflow-y-auto")) {
          safe_join(choices.map { |option_value, label, count|
            chosen = option_value == value
            link_to(url.(option_value), class: RECORDS_MENU_ITEM, role: "menuitemradio", "aria-checked": chosen.to_s) do
              safe_join([(menu_check if chosen),
                         tag.span(label, class: "min-w-0 flex-1 truncate"),
                         tag.span(records_t("history.filter_menu.count", count:), class: "shrink-0 text-xs text-muted-foreground tabular-nums")].compact)
            end
          })
        }
      ])
    end
  end

  # The device choices, labelled as typle-r does: deleted devices are marked.
  def records_device_choices(device_options, mark_deleted: false)
    device_options.map { |option|
      label = option.value == ListRanking::NO_DEVICE ? records_t("format.no_device_recorded") : records_device(option.latest)
      label = records_t("rankings.filter.deleted", name: label) if mark_deleted && option.deleted
      [option.value, label, option.count]
    }
  end

  # ModeToggle / OrderToggle (typle-r's Radix RadioGroup): radio buttons, the chosen one raised; choosing one opens its URL.
  def records_pill(label:, items:, item_class: RECORDS_PILL_ITEM, **options)
    tag.div(role: "radiogroup", class: RECORDS_PILL, "aria-label": label, "aria-orientation": "horizontal", data: { controller: "radio-group" }, **options) do
      safe_join(items.map { |text, url, current, data = {}|
        tag.button(tag.span(text), type: "button", role: "radio", class: item_class, "aria-checked": current.to_s, tabindex: (current ? 0 : -1),
          data: { url:, radio_group_target: "radio", action: "radio-group#choose keydown->radio-group#key", **data })
      })
    end
  end

  def records_rank_badge(rank)
    tag.span(rank, class: cn("grid size-6 place-items-center rounded-full bg-muted text-xs font-bold text-muted-foreground", rank == 1 && "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300"))
  end

  # speedScale: three tidy ticks around the values.
  def records_speed_scale(values)
    tidy = ->(value) { value.round(6) }
    nice = lambda do |value|
      power = 10.0**Math.log10(value).floor
      fraction = value / power
      tidy.((fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 2.5 ? 2.5 : fraction <= 5 ? 5 : 10) * power)
    end
    min, max = values.minmax
    step = nice.([max - min, max * 0.1, 0.01].max / 2)
    low = tidy.((min / step).floor * step)
    while tidy.(low + step * 2) < max
      step = nice.(step * 1.001)
      low = tidy.((min / step).floor * step)
    end
    decimals = step.to_s.sub(/\.0\z/, "").split(".")[1].to_s.size
    { domain: [low, tidy.(low + step * 2)], ticks: [tidy.(low + step * 2), tidy.(low + step), low], decimals: }
  end
end
