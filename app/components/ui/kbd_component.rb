# typle-r's Kbd: a key on the keyboard (inside a default Button, it takes the button's colours).
class Ui::KbdComponent < ApplicationComponent
  def initialize(text, class: nil)
    @text = text
    @class = class_option(binding)
  end

  def call
    tag.kbd(@text, class: cn("inline-flex h-5 items-center rounded border bg-background px-1.5 font-sans text-[11px] font-medium text-muted-foreground in-data-[variant=default]:border-current/30 in-data-[variant=default]:bg-transparent in-data-[variant=default]:text-current", @class))
  end
end
