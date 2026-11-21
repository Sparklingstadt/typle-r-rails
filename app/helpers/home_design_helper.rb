# The home dashboard and the landing page as typle-r draws them (src/components/Dashboard, src/app/page.tsx), with
# typle-r's wording from config/locales/design/home.*.yml and its date and duration formats (src/i18n/useFormat.ts).
module HomeDesignHelper
  def home_t(key, **options) = t("design.home.#{key}", **options)

  # A message with markup in it (typle-r's t.rich): each %{name} is replaced by the given HTML, the rest is escaped.
  def home_rich(key, **parts)
    safe_join(home_t(key).split(/(%\{\w+\})/).map { |piece| piece.match?(/\A%\{\w+\}\z/) ? parts.fetch(piece[2..-2].to_sym) : piece })
  end

  # --- dates and durations ---

  def home_date_values(time)
    { year: time.year, month: time.month, day: time.day, mm: format("%02d", time.month), dd: format("%02d", time.day),
      month_name: home_t("format.month_names")[time.month], hh: format("%02d", time.hour), minute: format("%02d", time.min),
      hour12: format("%02d", (time.hour % 12).nonzero? || 12), ampm: time.hour < 12 ? "AM" : "PM", period: time.hour < 12 ? "上午" : "下午" }
  end

  # The date, with the year only when it is not this year.
  def home_date(time, now = Time.current)
    home_t(time.year == now.year ? "format.month_day" : "format.year_month_day", **home_date_values(time))
  end

  # 今日, 昨日 or the date.
  def home_day(time, now = Time.current)
    days = (now.to_date - time.to_date).to_i
    return home_t("format.today") if days.zero?
    return home_t("format.yesterday") if days == 1
    home_date(time, now)
  end

  def home_date_with_weekday(time, now = Time.current)
    home_t("format.date_with_weekday", date: home_date(time, now), weekday: home_t("format.weekday_names")[time.wday])
  end

  def home_short_date(time) = home_t("format.short_date", **home_date_values(time))
  def home_short_date_time(time) = home_t("format.short_date_time", **home_date_values(time))

  # Practice time as [value, unit] pairs: seconds under a minute, minutes and seconds under an hour, else hours and minutes.
  def home_duration_parts(seconds)
    total = seconds.round
    unit = ->(name) { home_t("format.units.#{name}") }
    return [[total.to_s, unit.(:seconds)]] if total < 60
    return [[(total / 60).to_s, unit.(:minutes)], [(total % 60).to_s, unit.(:seconds)]] if total < 3600
    [[(total / 3600).to_s, unit.(:hours)], [(total % 3600 / 60).to_s, unit.(:minutes)]]
  end

  def home_duration(seconds)
    (first, first_unit), second = home_duration_parts(seconds)
    return home_t("format.time.one", value: first, unit: first_unit) unless second
    home_t("format.time.two", first:, firstUnit: first_unit, second: second[0], secondUnit: second[1])
  end

  # A number and its unit styled apart get a space between them where the language writes one.
  def home_unit_space? = home_t("format.time.one", value: "1", unit: "x").match?(/\s/)

  # A word's meaning: its annotation, without the word itself when the annotation starts with it ("apple / りんご").
  def home_word_meaning(display, annotation)
    note = annotation.to_s.strip
    rest = display.present? && note.start_with?(display) ? note[display.size..] : ""
    rest.match?(/\A\s*\//) ? rest.sub(/\A\s*\/\s*/, "").strip : note
  end

  # --- changes (typle-r's Delta.tsx) ---

  def home_delta(icon:, good:, text:)
    tag.p(class: cn("flex gap-1 text-xs", good ? "text-green-700 dark:text-green-400" : "text-muted-foreground")) do
      safe_join([icon(icon, class: "mt-0.5 size-3.5 shrink-0"), text])
    end
  end

  def home_week_delta(current, previous, &formatter)
    return { icon: "minus", good: false, text: home_t("dashboard.week.same_as_last_week") } if formatter.((current - previous).abs) == formatter.(0)
    more = current > previous
    { icon: more ? "trending-up" : "trending-down", good: more,
      text: home_t(more ? "dashboard.week.more_than_last_week" : "dashboard.week.less_than_last_week", value: formatter.((current - previous).abs)) }
  end

  # kind :seconds (lower is better) or :points.
  def home_change_delta(change, kind, named_recent: true)
    recent = !named_recent ? "none" : change.recent_count == 1 ? "latest" : "other"
    previous = change.previous_count == 1 ? "latest" : "other"
    values = { recentCount: change.recent_count, previousCount: change.previous_count }
    difference = change.recent - change.previous
    value = format(kind == :seconds ? "%.2f" : "%.1f", difference.abs)
    if value.to_f.zero?
      return { icon: "minus", good: false, text: home_t("dashboard.change.same_recent_#{recent}_previous_#{previous}", **values) }
    end
    text = home_t("dashboard.change.#{kind}_direction_#{difference.positive? ? "up" : "other"}", value:)
    { icon: difference.positive? ? "trending-up" : "trending-down", good: difference.positive? != (kind == :seconds),
      text: home_t("dashboard.change.different_recent_#{recent}_previous_#{previous}", **values, difference: text) }
  end

  # --- the trend chart (typle-r's TrendChart.tsx); the trend-chart controller reads it out by pointer and keys ---

  def home_trend_chart(label, points, scale, &formatter)
    last = points.size - 1
    x = ->(index) { (index.to_f / last * 100).round(3) }
    y = ->(value) { ((1 - (value - scale.low) / (scale.high - scale.low).to_f) * 100).round(3) }
    line = points.each_with_index.map { |point, index| "#{index.zero? ? "M" : "L"}#{x.(index)} #{y.(point.value)}" }.join(" ")
    latest = points.last
    tag.figure(class: "flex flex-col gap-1") do
      safe_join([
        tag.div(class: "flex gap-1.5") do
          safe_join([
            tag.div(class: "relative my-2 w-8 shrink-0 text-[11px] text-muted-foreground tabular-nums", "aria-hidden": "true") do
              safe_join(scale.ticks.map { |tick|
                tag.span(format("%.#{scale.decimals}f", tick), class: "absolute right-0 -translate-y-1/2 leading-none", style: "top: #{y.(tick)}%")
              })
            end,
            tag.div(class: "relative h-[72px] min-w-0 flex-1 cursor-crosshair touch-pan-y rounded-sm py-2 outline-none focus-visible:ring-3 focus-visible:ring-ring/50", role: "slider", tabindex: 0,
                    "aria-label": home_t("dashboard.chart.label", label:), "aria-valuemin": 1, "aria-valuemax": points.size, "aria-valuenow": points.size,
                    "aria-valuetext": "#{home_short_date_time(latest.time)} #{formatter.(latest.value)}",
                    data: { controller: "trend-chart", action: "focus->trend-chart#focus blur->trend-chart#blur pointermove->trend-chart#point pointerdown->trend-chart#point pointerleave->trend-chart#leave keydown->trend-chart#key",
                            trend_chart_points_value: points.each_with_index.map { |point, index| { x: x.(index), y: y.(point.value), value: formatter.(point.value), date: home_short_date_time(point.time) } }.to_json }) do
              tag.div(class: "relative mx-1 h-full") do
                safe_join([
                  tag.svg(viewBox: "0 0 100 100", preserveAspectRatio: "none", class: "absolute inset-0 size-full overflow-visible", "aria-hidden": "true") do
                    safe_join([
                      *scale.ticks.map { |tick| tag.line(x1: 0, x2: 100, y1: y.(tick), y2: y.(tick), class: "stroke-border", "stroke-width": 1, "vector-effect": "non-scaling-stroke") },
                      tag.path(d: "#{line} L#{x.(last)} 100 L0 100 Z", class: "fill-trend/10"),
                      tag.path(d: line, class: "stroke-trend", fill: "none", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round", "vector-effect": "non-scaling-stroke"),
                      tag.line(x1: 0, x2: 0, y1: 0, y2: 100, class: "stroke-muted-foreground/60", "stroke-width": 1, "vector-effect": "non-scaling-stroke", style: "display: none", data: { trend_chart_target: "cursor" })
                    ])
                  end,
                  tag.span(class: "absolute size-2.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-trend ring-2 ring-card", style: "left: #{x.(last)}%; top: #{y.(latest.value)}%", "aria-hidden": "true", data: { trend_chart_target: "dot" }),
                  trend_chart_tooltip
                ])
              end
            end
          ])
        end,
        tag.figcaption(class: "flex justify-between pl-10 text-[11px] text-muted-foreground tabular-nums", "aria-hidden": "true") do
          safe_join([tag.span(home_short_date(points.first.time)), tag.span(home_short_date(latest.time))])
        end,
        tag.table(class: "sr-only") do
          safe_join([
            tag.caption(label),
            tag.thead(tag.tr(safe_join([tag.th(home_t("dashboard.chart.date"), scope: "col"), tag.th(home_t("dashboard.chart.value"), scope: "col")]))),
            tag.tbody(safe_join(points.map { |point| tag.tr(safe_join([tag.td(home_short_date_time(point.time)), tag.td(formatter.(point.value))])) }))
          ])
        end
      ])
    end
  end

  # --- landing page ---

  HOME_PROGRAMMING = "プログラミング"
  HOME_LANGUAGES = "語学"

  # The official list counts (all lists, programming, languages), as typle-r's officialListCounts.
  def home_official_counts
    lists = OfficialCatalog.packs.flat_map(&:lists)
    { total: lists.size, programming: lists.count { |l| l.category == HOME_PROGRAMMING }, languages: lists.count { |l| l.category == HOME_LANGUAGES } }
  end

  # The first words shown of an official pack (its first list).
  def home_first_words(catalog_id, count) = OfficialCatalog.find(catalog_id)&.lists&.first&.words&.first(count)&.map { |w| w[:display] } || []
end
