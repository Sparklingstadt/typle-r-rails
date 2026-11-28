# A pack's lists (Packs::ListRowComponent each), as its row shows them once it is open: in the row itself when the page
# opens with it open, otherwise in the frame PacksController#lists fills when the row is opened.
class Packs::ListsComponent < ApplicationComponent
  def initialize(pack:, pointed_list_id: nil)
    @pack = pack
    @pointed_list_id = pointed_list_id
  end

  def call
    tag.ul(aria: { label: t("design.lists.pack.lists_of", name: @pack.name) }, class: "divide-y") do
      safe_join(@pack.word_lists.map { |list| render Packs::ListRowComponent.new(list:, pointed: list.id == @pointed_list_id) })
    end
  end
end
