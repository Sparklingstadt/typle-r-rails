# The icon at the top of an EmptyState, in a muted circle.
class Ui::EmptyState::IconComponent < ApplicationComponent
  def initialize(name, class: nil)
    @name = name
    @class = class_option(binding)
  end

  def call
    tag.span(icon(@name, class: "size-6"), class: cn("grid size-12 place-items-center rounded-full bg-muted text-muted-foreground", @class))
  end
end
