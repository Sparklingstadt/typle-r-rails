# typle-r's shadcn/ui components (typle-r/src/components/ui) as helpers: the same class strings, merged the way `cn()`
# merges them, so a page written with these looks the same as typle-r's.
module UiHelper
  include Ui::Classes

  # The ItemIndicator of a chosen item; `peer: true` shows it only while the input before it is checked.
  def menu_check(peer: false)
    tag.span(icon(:check, class: "size-4"), class: cn("pointer-events-none absolute left-2.5 inline-flex", peer && "opacity-0 peer-checked:opacity-100"), "aria-hidden": "true")
  end

  # A lucide icon (the set typle-r uses), hidden from screen readers unless it is given a label.
  # Without a size class it is 1rem (application.css), and a button's own size for icons wins, as with lucide-react.
  def icon(name, class: nil, **options)
    lucide_icon(name.to_s, class: cn("lucide lucide-#{name}", binding.local_variable_get(:class)), "aria-hidden": "true", **options)
  end

  # TrendChart's tooltip: the value and date of the run being read, above it (the trend-chart controller fills it).
  def trend_chart_tooltip
    tag.div(hidden: true, "aria-hidden": "true", data: { trend_chart_target: "tooltip" },
            class: "pointer-events-none absolute bottom-full z-10 mb-3 flex flex-col whitespace-nowrap rounded-md bg-popover px-2 py-1 text-popover-foreground shadow-md ring-1 ring-foreground/10") do
      safe_join([tag.span(class: "text-sm font-semibold tabular-nums", data: { trend_chart_target: "tooltipValue" }),
                 tag.span(class: "text-xs text-muted-foreground", data: { trend_chart_target: "tooltipDate" })])
    end
  end

  # Ui::ButtonComponent as an <a> (typle-r's <Button asChild><Link/></Button>).
  def link_button(label = nil, url = nil, **options, &block)
    url, label = label, nil if block
    render(Ui::ButtonComponent.new(label, url:, as: :link, **options), &block)
  end

  # Ui::ButtonComponent as a <button> that opens a page (戻る, キャンセル).
  def visit_button(label = nil, url = nil, **options, &block)
    url, label = label, nil if block
    render(Ui::ButtonComponent.new(label, url:, as: :visit, **options), &block)
  end

  # Ui::ButtonComponent as button_to's form.
  def form_button(label, url, **options) = render(Ui::ButtonComponent.new(label, url:, as: :form, **options))

  def ui_badge(text = nil, variant: :default, class: nil, **options, &block)
    tag.span(block ? capture(&block) : text, class: badge_classes(variant:, class: binding.local_variable_get(:class)), "data-slot": "badge", **options)
  end

  # Ui::CardComponent and its parts (Ui::Card).
  def card(**options, &block) = render(Ui::CardComponent.new(**options), &block)
  def card_header(**options, &block) = render(Ui::Card::HeaderComponent.new(**options), &block)
  def card_title(text = nil, **options, &block) = render(Ui::Card::TitleComponent.new(text, **options), &block)
  def card_description(text = nil, **options, &block) = render(Ui::Card::DescriptionComponent.new(text, **options), &block)
  def card_action(**options, &block) = render(Ui::Card::ActionComponent.new(**options), &block)
  def card_content(**options, &block) = render(Ui::Card::ContentComponent.new(**options), &block)
  def card_footer(**options, &block) = render(Ui::Card::FooterComponent.new(**options), &block)

  def empty_note(text = nil, class: nil, &block) = tag.p(block ? capture(&block) : text, class: cn(EMPTY_NOTE, binding.local_variable_get(:class)), "data-slot": "empty-note")

  def empty_state(class: nil, &block) = tag.div(capture(&block), class: cn(EMPTY_STATE, binding.local_variable_get(:class)), "data-slot": "empty-state")

  def empty_state_icon(name, class: nil)
    tag.span(icon(name, class: "size-6"), class: cn("grid size-12 place-items-center rounded-full bg-muted text-muted-foreground", binding.local_variable_get(:class)))
  end

  def icon_tile(name, class: nil)
    tag.span(icon(name, class: "size-5"), class: cn("grid size-10 place-items-center rounded-lg bg-muted text-muted-foreground", binding.local_variable_get(:class)), "data-slot": "icon-tile")
  end

  # PageMain: the centered main column of a page.
  def page_main(width: :wide, class: nil, &block)
    tag.main(capture(&block), class: cn("mx-auto w-full px-4 pt-8 pb-16 sm:px-6 lg:px-8", PAGE_WIDTHS.fetch(width), binding.local_variable_get(:class)), "data-slot": "page-main")
  end

  # PageHeader: the page's heading and description, with `block` at the end of the row.
  def page_header(title, description = nil, plain: false, &block)
    safe_join([page_header_tag(title, description, plain:, &block), page_alert].compact)
  end

  def page_header_tag(title, description = nil, plain: false, &block)
    content_for(:title, title) unless content_for?(:title)
    # The settings pages' header (typle-r's settings and input pages): the title and description alone, full width.
    if plain
      return tag.header(class: "mb-6 space-y-1") { safe_join([tag.h1(title, class: "text-2xl font-bold"), (tag.p(description, class: "text-sm text-muted-foreground") if description)].compact) }
    end
    tag.header(class: "mb-6 flex flex-wrap items-end justify-between gap-3", "data-slot": "page-header") do
      safe_join([
        tag.div(class: "space-y-1") { safe_join([tag.h1(title, class: "text-2xl font-bold"), (tag.p(description, class: "text-sm text-muted-foreground") if description)].compact) },
        (capture(&block) if block)
      ].compact)
    end
  end

  # typle-r's ErrorAlert, under the page's header: what a request refused (the flash alert), shown once.
  def page_alert
    return if alert.blank? || @page_alert_shown
    @page_alert_shown = true
    tag.div(role: "alert", class: alert_classes(:destructive, "mb-6 border-destructive/40 bg-destructive/5")) do
      safe_join([icon("circle-alert"), tag.div(alert, "data-slot": "alert-description", class: "text-sm")])
    end
  end

  def search_field(name:, value:, placeholder:, label:, class: "h-9")
    tag.label(class: cn(SEARCH_FIELD, binding.local_variable_get(:class))) do
      safe_join([icon(:search, class: "size-4 shrink-0"),
                 search_field_tag(name, value, placeholder:, "aria-label": label, autocomplete: "off", class: "min-w-0 flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground")])
    end
  end

  # ClearableSearchField: the icon inside the field, and a button that empties it (`clear_url`, as this is a GET form).
  def clearable_search_field(name:, value:, label:, size: :default, input_class: nil, class: nil, clear_url: nil, clear_label: nil)
    sizes = CLEARABLE_SEARCH_SIZES.fetch(size)
    tag.label(class: cn("relative min-w-0 flex-1", binding.local_variable_get(:class)), "data-slot": "search-field") do
      safe_join([
        tag.span(label, class: "sr-only"),
        icon(:search, class: cn("pointer-events-none absolute top-1/2 size-4 -translate-y-1/2 text-muted-foreground", sizes[:icon])),
        search_field_tag(name, value, placeholder: label, autocomplete: "off",
          class: cn("w-full rounded-lg border border-input text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30 [&::-webkit-search-cancel-button]:hidden", sizes[:input], input_class)),
        (link_to(icon(:x, class: "size-3.5"), clear_url, "aria-label": clear_label,
          class: cn("absolute top-1/2 grid -translate-y-1/2 place-items-center rounded-md text-muted-foreground outline-none hover:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50", sizes[:button])) if value.present? && clear_url)
      ].compact)
    end
  end

  # Kbd: a key on the keyboard.
  def kbd(text, class: nil) = tag.kbd(text, class: cn("inline-flex h-5 items-center rounded border bg-background px-1.5 font-sans text-[11px] font-medium text-muted-foreground in-data-[variant=default]:border-current/30 in-data-[variant=default]:bg-transparent in-data-[variant=default]:text-current", binding.local_variable_get(:class)))
end
