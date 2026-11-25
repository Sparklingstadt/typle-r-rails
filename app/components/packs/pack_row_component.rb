# typle-r's PackRow: a pack as one row that opens to show its lists (Packs::ListRowComponent), with its actions in a menu.
# `pointed` marks the row a save came back to (typle-r's /edit?pack=): it is open, and highlighted for a moment;
# `open` opens it without pointing at it. `pointed_list_id` is the list pointed at in it, if any.
class Packs::PackRowComponent < ApplicationComponent
  delegate :tt, :lists_labels, :lists_pack_category, :lists_pack_records, :lists_practice_text, :lists_practice_target, :lists_menu,
           :lists_menu_separator, :ui_badge, :delete_confirm_data, :unfollow_confirm_data, to: :helpers

  def initialize(pack:, pointed: false, open: false, pointed_list_id: nil)
    @pack = pack
    @pointed = pointed
    @open = open
    @pointed_list_id = pointed_list_id
  end

  private

  attr_reader :pack

  def pointed? = @pointed

  def open? = @open || @pointed

  def lists = pack.word_lists

  def records = @records ||= lists_pack_records(pack)

  def practiced = lists.count { |list| list.practice_records.any? }

  def words_text = t("design.lists.pack.word_count", count: lists.sum { |list| list.words.size })

  def panel_id = "pack-#{pack.id}"
end
