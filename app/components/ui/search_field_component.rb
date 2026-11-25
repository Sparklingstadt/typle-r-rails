# A search field with its icon inside the border, for a filter that the page's script applies as one types.
class Ui::SearchFieldComponent < ApplicationComponent
  def initialize(name:, value:, placeholder:, label:, class: "h-9")
    @name = name
    @value = value
    @placeholder = placeholder
    @label = label
    @class = class_option(binding)
  end

  def call
    tag.label(class: cn(SEARCH_FIELD, @class)) do
      safe_join([ icon(:search, class: "size-4 shrink-0"),
                  search_field_tag(@name, @value, placeholder: @placeholder, "aria-label": @label, autocomplete: "off",
                    class: "min-w-0 flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground") ])
    end
  end
end
