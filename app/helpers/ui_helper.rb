# typle-r's shadcn/ui components (typle-r/src/components/ui) as helpers: the same class strings, merged the way `cn()`
# merges them, so a page written with these looks the same as typle-r's.
module UiHelper
  MERGER = TailwindMerge::Merger.new

  BUTTON_BASE = "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"
  BUTTON_VARIANTS = {
    default: "bg-primary text-primary-foreground hover:bg-primary/90",
    outline: "border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50",
    secondary: "bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground",
    ghost: "hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50",
    destructive: "bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40",
    link: "text-primary underline-offset-4 hover:underline"
  }.freeze
  BUTTON_SIZES = {
    default: "h-11 gap-1.5 px-4 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
    xs: "h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3",
    sm: "h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5",
    lg: "h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
    icon: "size-8",
    "icon-xs": "size-6 rounded-[min(var(--radius-md),10px)] [&_svg:not([class*='size-'])]:size-3",
    "icon-sm": "size-7 rounded-[min(var(--radius-md),12px)]",
    "icon-lg": "size-9"
  }.freeze

  BADGE_BASE = "group/badge inline-flex h-5 w-fit shrink-0 items-center justify-center gap-1 overflow-hidden rounded-4xl border border-transparent px-2 py-0.5 text-xs font-medium whitespace-nowrap transition-all focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 [&>svg]:pointer-events-none [&>svg]:size-3!"
  BADGE_VARIANTS = {
    default: "bg-primary text-primary-foreground [a]:hover:bg-primary/80",
    secondary: "bg-secondary text-secondary-foreground [a]:hover:bg-secondary/80",
    destructive: "bg-destructive/10 text-destructive dark:bg-destructive/20 [a]:hover:bg-destructive/20",
    outline: "border-border text-foreground [a]:hover:bg-muted [a]:hover:text-muted-foreground",
    ghost: "hover:bg-muted hover:text-muted-foreground dark:hover:bg-muted/50",
    link: "text-primary underline-offset-4 hover:underline"
  }.freeze

  CARD = "group/card flex flex-col gap-(--card-spacing) overflow-hidden rounded-xl bg-card py-(--card-spacing) text-sm text-card-foreground ring-1 ring-foreground/10 [--card-spacing:--spacing(4)] has-data-[slot=card-footer]:pb-0 data-[size=sm]:[--card-spacing:--spacing(3)] data-[size=sm]:has-data-[slot=card-footer]:pb-0"
  CARD_HEADER = "group/card-header grid auto-rows-min items-start gap-1 rounded-t-xl px-(--card-spacing) has-data-[slot=card-action]:grid-cols-[1fr_auto] has-data-[slot=card-description]:grid-rows-[auto_auto] [.border-b]:pb-(--card-spacing)"
  CARD_TITLE = "font-heading text-base leading-snug font-medium group-data-[size=sm]/card:text-sm"
  CARD_DESCRIPTION = "text-sm text-muted-foreground"
  CARD_ACTION = "col-start-2 row-span-2 row-start-1 self-start justify-self-end"
  CARD_CONTENT = "px-(--card-spacing)"
  CARD_FOOTER = "flex items-center rounded-b-xl border-t bg-muted/50 p-(--card-spacing)"
  CARD_LIST = "divide-y overflow-hidden rounded-xl border bg-card"

  INPUT = "h-8 w-full min-w-0 rounded-lg border border-input bg-transparent px-2.5 py-1 text-base transition-colors outline-none file:inline-flex file:h-6 file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 md:text-sm dark:bg-input/30 dark:disabled:bg-input/80 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40"
  TEXTAREA = "flex field-sizing-content min-h-16 w-full rounded-lg border border-input bg-transparent px-2.5 py-2 text-base transition-colors outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 md:text-sm dark:bg-input/30 dark:disabled:bg-input/80 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40"
  SELECT_BASE = "rounded-lg border outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
  SELECT_VARIANTS = {
    form: "h-11 w-full min-w-0 border-input bg-transparent px-2.5 text-base md:text-sm dark:bg-input/30 dark:[&>option]:bg-popover",
    filter: "h-9 w-full min-w-0 bg-background px-2 text-sm dark:bg-input/30",
    compact: "h-8 border-input bg-transparent px-2.5 text-sm dark:bg-input/30"
  }.freeze
  LABEL = "flex items-center gap-2 text-sm leading-none font-medium select-none peer-disabled:cursor-not-allowed peer-disabled:opacity-50"
  SWITCH = "peer relative inline-flex h-6 w-11 shrink-0 cursor-pointer appearance-none items-center rounded-full border border-transparent bg-input shadow-xs transition-all outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 checked:bg-primary dark:bg-input/80 dark:checked:bg-primary before:pointer-events-none before:block before:size-5 before:translate-x-0.5 before:rounded-full before:bg-background before:transition-transform before:content-[''] checked:before:translate-x-[calc(100%)] dark:before:bg-foreground dark:checked:before:bg-primary-foreground"

  TABLE = "w-full caption-bottom text-sm"
  TABLE_HEADER = "[&_tr]:border-b"
  TABLE_BODY = "[&_tr:last-child]:border-0"
  TABLE_ROW = "border-b transition-colors hover:bg-muted/50"
  TABLE_HEAD = "h-10 px-2 text-left align-middle font-medium whitespace-nowrap text-foreground"
  TABLE_CELL = "p-2 align-middle whitespace-nowrap"

  ALERT = "group/alert relative grid w-full gap-0.5 rounded-lg border px-2.5 py-2 text-left text-sm has-[>svg]:grid-cols-[auto_1fr] has-[>svg]:gap-x-2 *:[svg]:row-span-2 *:[svg]:translate-y-0.5 *:[svg]:text-current *:[svg:not([class*='size-'])]:size-4"
  ALERT_VARIANTS = { default: "bg-card text-card-foreground", destructive: "bg-card text-destructive *:data-[slot=alert-description]:text-destructive/90 *:[svg]:text-current" }.freeze
  EMPTY_NOTE = "rounded-xl border border-dashed bg-card px-5 py-6 text-sm text-muted-foreground"
  EMPTY_STATE = "flex flex-col items-center gap-4 rounded-xl border border-dashed bg-card px-6 text-center"
  SEARCH_FIELD = "flex items-center gap-2 rounded-lg border px-3 text-muted-foreground focus-within:border-ring focus-within:ring-3 focus-within:ring-ring/50"

  PAGE_WIDTHS = { narrow: "max-w-4xl", medium: "max-w-5xl", wide: "max-w-6xl" }.freeze

  # cn(): joins classes, the later winning over the earlier as tailwind-merge decides.
  def cn(*classes) = MERGER.merge(classes.flatten.compact.join(" "))

  def button_classes(variant: :default, size: :default, class: nil)
    cn(BUTTON_BASE, BUTTON_VARIANTS.fetch(variant.to_sym), BUTTON_SIZES.fetch(size.to_sym), binding.local_variable_get(:class))
  end

  def badge_classes(variant: :default, class: nil) = cn(BADGE_BASE, BADGE_VARIANTS.fetch(variant.to_sym), binding.local_variable_get(:class))
  def select_classes(variant, extra = nil) = cn(SELECT_BASE, SELECT_VARIANTS.fetch(variant.to_sym), extra)
  def input_classes(extra = nil) = cn(INPUT, extra)
  def textarea_classes(extra = nil) = cn(TEXTAREA, extra)
  def label_classes(extra = nil) = cn(LABEL, extra)
  def alert_classes(variant = :default, extra = nil) = cn(ALERT, ALERT_VARIANTS.fetch(variant.to_sym), extra)

  # A lucide icon (the set typle-r uses), hidden from screen readers unless it is given a label.
  # shadcn's DropdownMenuContent and its RadioItem / CheckboxItem (the "inset" item with a check at the left).
  MENU_CONTENT = "z-50 rounded-lg border bg-popover p-1 text-popover-foreground shadow-md"
  MENU_INSET_ITEM = "relative flex w-full cursor-pointer items-center gap-2 rounded-md py-2 pr-3 pl-8 text-left text-sm outline-none select-none hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent focus-visible:text-accent-foreground has-focus-visible:bg-accent has-focus-visible:text-accent-foreground"

  # The ItemIndicator of a chosen item; `peer: true` shows it only while the input before it is checked.
  def menu_check(peer: false)
    tag.span(icon(:check, class: "size-4"), class: cn("pointer-events-none absolute left-2.5 inline-flex", peer && "opacity-0 peer-checked:opacity-100"), "aria-hidden": "true")
  end

  # Without a size class it is 1rem (application.css), and a button's own size for icons wins, as with lucide-react.
  def icon(name, class: nil, **options)
    lucide_icon(name.to_s, class: cn("lucide lucide-#{name}", binding.local_variable_get(:class)), "aria-hidden": "true", **options)
  end

  # <a> styled as a Button (typle-r's <Button asChild><Link/></Button>).
  # A button that opens a page, for typle-r's buttons that navigate (戻る, キャンセル): read as a button, not a link.
  # The click is handled in application.js; an editor's unsaved-changes check still runs (turbo:before-visit).
  def visit_button(label = nil, url = nil, variant: :default, size: :default, class: nil, icon: nil, **options, &block)
    url, label = label, nil if block
    classes = button_classes(variant:, size:, class: binding.local_variable_get(:class))
    tag.button(type: "button", class: classes, "data-slot": "button", "data-variant": variant, "data-size": size, "data-visit-url": url, **options) do
      safe_join([(icon(icon) if icon), block ? capture(&block) : label].compact)
    end
  end

  # TrendChart's tooltip: the value and date of the run being read, above it (the trend-chart controller fills it).
  def trend_chart_tooltip
    tag.div(hidden: true, "aria-hidden": "true", data: { trend_chart_target: "tooltip" },
            class: "pointer-events-none absolute bottom-full z-10 mb-3 flex flex-col whitespace-nowrap rounded-md bg-popover px-2 py-1 text-popover-foreground shadow-md ring-1 ring-foreground/10") do
      safe_join([tag.span(class: "text-sm font-semibold tabular-nums", data: { trend_chart_target: "tooltipValue" }),
                 tag.span(class: "text-xs text-muted-foreground", data: { trend_chart_target: "tooltipDate" })])
    end
  end

  def link_button(label = nil, url = nil, variant: :default, size: :default, class: nil, icon: nil, **options, &block)
    url, label = label, nil if block
    classes = button_classes(variant:, size:, class: binding.local_variable_get(:class))
    link_to(url, class: classes, "data-slot": "button", "data-variant": variant, "data-size": size, **options) do
      safe_join([(icon(icon) if icon), block ? capture(&block) : label].compact)
    end
  end

  # button_to styled as a Button.
  def form_button(label, url, variant: :default, size: :default, class: nil, icon: nil, form_class: "contents", **options)
    classes = button_classes(variant:, size:, class: binding.local_variable_get(:class))
    button_to(url, class: classes, form_class:, "data-slot": "button", "data-variant": variant, "data-size": size, **options) do
      safe_join([(icon(icon) if icon), label].compact)
    end
  end

  def ui_badge(text = nil, variant: :default, class: nil, **options, &block)
    tag.span(block ? capture(&block) : text, class: badge_classes(variant:, class: binding.local_variable_get(:class)), "data-slot": "badge", **options)
  end

  def card(size: :default, class: nil, tag_name: :div, **options, &block)
    content_tag(tag_name, capture(&block), class: cn(CARD, binding.local_variable_get(:class)), "data-slot": "card", "data-size": size, **options)
  end

  def card_header(class: nil, &block) = tag.div(capture(&block), class: cn(CARD_HEADER, binding.local_variable_get(:class)), "data-slot": "card-header")
  def card_title(text = nil, class: nil, tag_name: :div, &block) = content_tag(tag_name, block ? capture(&block) : text, class: cn(CARD_TITLE, binding.local_variable_get(:class)), "data-slot": "card-title")
  def card_description(text = nil, class: nil, &block) = tag.div(block ? capture(&block) : text, class: cn(CARD_DESCRIPTION, binding.local_variable_get(:class)), "data-slot": "card-description")
  def card_action(class: nil, &block) = tag.div(capture(&block), class: cn(CARD_ACTION, binding.local_variable_get(:class)), "data-slot": "card-action")
  def card_content(class: nil, &block) = tag.div(capture(&block), class: cn(CARD_CONTENT, binding.local_variable_get(:class)), "data-slot": "card-content")
  def card_footer(class: nil, &block) = tag.div(capture(&block), class: cn(CARD_FOOTER, binding.local_variable_get(:class)), "data-slot": "card-footer")

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

  CLEARABLE_SEARCH_SIZES = {
    default: { icon: "left-3", input: "h-10 pr-9 pl-9", button: "right-2 size-7" },
    sm: { icon: "left-2.5", input: "h-9 pr-8 pl-8", button: "right-1.5 size-6" }
  }.freeze

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
