# typle-r's ClearableSearchField: the icon inside the field, and a link that empties it (`clear_url`, as this is a GET
# form), shown while there is something to clear.
class Ui::ClearableSearchFieldComponent < ApplicationComponent
  SIZES = {
    default: { icon: "left-3", input: "h-10 pr-9 pl-9", button: "right-2 size-7" },
    sm: { icon: "left-2.5", input: "h-9 pr-8 pl-8", button: "right-1.5 size-6" }
  }.freeze

  def initialize(name:, value:, label:, size: :default, input_class: nil, class: nil, clear_url: nil, clear_label: nil)
    @name = name
    @value = value
    @label = label
    @sizes = SIZES.fetch(size)
    @input_class = input_class
    @class = class_option(binding)
    @clear_url = clear_url
    @clear_label = clear_label
  end

  def call
    tag.label(class: cn("relative min-w-0 flex-1", @class), "data-slot": "search-field") do
      safe_join([
        tag.span(@label, class: "sr-only"),
        icon(:search, class: cn("pointer-events-none absolute top-1/2 size-4 -translate-y-1/2 text-muted-foreground", @sizes[:icon])),
        search_field_tag(@name, @value, placeholder: @label, autocomplete: "off",
          class: cn("w-full rounded-lg border border-input text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30 [&::-webkit-search-cancel-button]:hidden", @sizes[:input], @input_class)),
        (clear_link if @value.present? && @clear_url)
      ].compact)
    end
  end

  private

  def clear_link
    link_to(icon(:x, class: "size-3.5"), @clear_url, "aria-label": @clear_label,
      class: cn("absolute top-1/2 grid -translate-y-1/2 place-items-center rounded-md text-muted-foreground outline-none hover:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50", @sizes[:button]))
  end
end
