# A part of a Card (CardHeader, CardContent, ...): a div with its slot's name and classes, the text or the block in it.
class Ui::Card::PartComponent < ApplicationComponent
  def initialize(text = nil, class: nil, tag_name: :div)
    @text = text
    @class = class_option(binding)
    @tag_name = tag_name
  end

  def call
    content_tag(@tag_name, content? ? content : @text, class: cn(self.class::CLASSES, @class), "data-slot": self.class::SLOT)
  end
end
