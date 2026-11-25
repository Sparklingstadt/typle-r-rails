module Ui
  # typle-r's shadcn/ui class strings (typle-r/src/components/ui) and cn(), shared by the components (app/components)
  # and the helpers (UiHelper includes it, so UiHelper::CARD_LIST and the like still read them).
  module Classes
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

    # shadcn's DropdownMenuContent and its RadioItem / CheckboxItem (the "inset" item with a check at the left).
    MENU_CONTENT = "z-50 rounded-lg border bg-popover p-1 text-popover-foreground shadow-md"
    MENU_INSET_ITEM = "relative flex w-full cursor-pointer items-center gap-2 rounded-md py-2 pr-3 pl-8 text-left text-sm outline-none select-none hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent focus-visible:text-accent-foreground has-focus-visible:bg-accent has-focus-visible:text-accent-foreground"


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
  end
end
