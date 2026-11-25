# typle-r's NextLists: lists to practise next, each with the reason it was picked (never practised, not practised for a
# while, or a low accuracy).
class Home::NextListsComponent < ApplicationComponent
  delegate :home_t, :home_day, :practice_name, :link_button, :ui_badge, to: :helpers

  def initialize(dashboard:, now:)
    @dashboard = dashboard
    @picks = dashboard.next_lists
    @now = now
  end

  private

  attr_reader :picks

  def last_practiced(list)
    last = @dashboard.last_normal_practice(list)
    last ? home_t("dashboard.next.last_practiced", day: home_day(last, @now)) : home_t("dashboard.next.no_records")
  end

  # The badge's icon and text for the reason a list was picked.
  def reason_badge(reason, args)
    case reason
    when :never then ["sparkles", home_t("dashboard.next.new")]
    when :idle then ["clock", home_t("dashboard.next.stale", days: args[:count], count: args[:count])]
    else ["target", home_t("dashboard.next.low_accuracy", count: args[:count], accuracy: format("%.1f", args[:accuracy]))]
    end
  end
end
