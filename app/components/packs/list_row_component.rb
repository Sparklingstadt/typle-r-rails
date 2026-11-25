# typle-r's ListRow: one list of a pack, with 練習 and 編集 up front and everything else in the menu. `pointed` marks the
# row a save came back to, highlighted for a moment.
class Packs::ListRowComponent < ApplicationComponent
  delegate :tt, :list_labels, :lists_word_preview, :lists_practice_text, :lists_menu, :lists_menu_separator, :link_button,
           :visit_button, :list_delete_confirm_data, to: :helpers

  def initialize(list:, pointed: false)
    @list = list
    @pointed = pointed
  end

  private

  attr_reader :list

  def pointed? = @pointed

  def records = list.practice_records

  def count_text = t("design.lists.row.word_count", count: list.words.size)
end
