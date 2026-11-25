# ベスト記録: each list's best runs, by mode (?mode=recall / ?mode=writing), ranked by accuracy or speed (?order=speed),
# on one device (?device=). The lists are grouped by pack and sorted (?sort=name / count); ?list= opens one list.
class RankingsController < ApplicationController
  SORTS = %w[recent name count].freeze
  PackRanking = Data.define(:pack, :items) do
    def practised? = items.any?(&:practised?)
    def practice_count = items.sum { |item| item.records.size }
    def practised_list_count = items.count { |item| item.records.any? }
    def last_practiced = items.filter_map(&:last_practiced).max
    def improved_count = items.count(&:improved?)
  end

  def index
    @mode = params[:mode].in?(%w[recall writing]) ? params[:mode] : nil
    @order = params[:order] == "speed" ? "speed" : "accuracy"
    @sort = params[:sort].in?(SORTS) ? params[:sort] : "recent"
    lists = current_user.word_lists.includes(:pack, :words, :practice_records).to_a
    @practised = lists.any? { |list| list.practice_records.any? }
    @device_options = DeviceOptions.new(current_user, lists.flat_map { |list| list.practice_records.to_a })
    @device = @device_options.option_for(params[:device])
    now = Time.current
    rankings = lists.map { |list| ListRanking.new(list, mode: @mode, device: @device&.value, order: @order, now:) }
    @packs = sort_packs(current_user.packs.filter_map { |pack|
      items = rankings.select { |ranking| ranking.list.pack_id == pack.id }
      PackRanking.new(pack:, items:) if items.any?
    })
    @requested = lists.find { |list| list.id.to_s == params[:list] }
    first_pack = @packs.find(&:practised?) || @packs.first
    recent = first_pack&.items&.select(&:practised?)&.max_by(&:last_practiced)
    selected = @requested || (recent || first_pack&.items&.first)&.list
    @show_all = params[:all].present?
    @include_others = params[:others].present?
    @detail = ListRanking.new(selected, mode: @mode, device: @device&.value, order: @order, include_others: @include_others, now:) if selected
  end

  private
    def sort_packs(packs)
      recent = ->(item) { -(item.last_practiced&.to_f || 0) }
      key = case @sort
      when "name" then ->(item) { [item.pack.name.downcase] }
      when "count" then ->(item) { [-item.practice_count, recent.(item)] }
      else ->(item) { [recent.(item)] }
      end
      # Ties keep the saved order.
      packs.each_with_index.sort_by { |item, index| [*key.(item), index] }.map(&:first)
    end
end
