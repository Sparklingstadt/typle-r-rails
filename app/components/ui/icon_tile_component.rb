# An icon in a muted rounded square, at the head of a row or a card.
class Ui::IconTileComponent < ApplicationComponent
  def initialize(name, class: nil)
    @name = name
    @class = class_option(binding)
  end

  def call
    tag.span(icon(@name, class: "size-5"), class: cn("grid size-10 place-items-center rounded-lg bg-muted text-muted-foreground", @class), "data-slot": "icon-tile")
  end
end
