# typle-r RankingList's ListItem (a list with a best: its best run, when it was last practised and whether it improved)
# and EmptyButton (a list without one). `grouped` rows sit under their pack, so they show the list's level alone.
# The row opens `href` (the list's ranking), and is marked while its list is the `selected` one.
class Rankings::ListRowComponent < ApplicationComponent
  delegate :records_t, :records_accuracy, :records_day, :records_level_name, :records_time, to: :helpers

  def initialize(ranking:, selected:, href:, grouped:, now:)
    @ranking = ranking
    @list = ranking.list
    @selected = selected
    @href = href
    @grouped = grouped
    @now = now
  end

  private

  attr_reader :ranking, :list, :href, :now

  def current? = list == @selected

  def name = @grouped ? records_level_name(list) : list.full_name

  def button_options = { type: "button", data: { visit_url: href }, "data-list-id": list.id, "aria-current": (current? ? "true" : nil) }
end
