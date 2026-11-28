require "application_system_test_case"

# The home dashboard: its trends come into their frame (HomeController#trends) after the page, and their links open
# the whole page.
class HomeSystemTest < ApplicationSystemTestCase
  test "the trends load as they scroll near, and their practice link leaves the dashboard" do
    visit catalog_path("pack-vim-beginner")
    click_on I18n.t("design.lists.official.practice")
    assert_selector "[data-practice-save-url-value]"
    visit catalog_path("pack-english-basic-words")
    click_on I18n.t("design.lists.official.practice")
    assert_selector "[data-practice-save-url-value]"
    charted, single = WordList.order(:id).to_a
    # Three runs draw the charts; one run shows the card's practice link instead.
    [3, 2, 1].each do |days|
      charted.practice_records.create!(user: charted.user, time_ms: 4000 + days * 100, accuracy: 90 + days, mistakes: 1,
        word_count: charted.words.size, practiced_at: days.days.ago)
    end
    single.practice_records.create!(user: single.user, time_ms: 5000, accuracy: 100, mistakes: 0, word_count: single.words.size,
      practiced_at: 1.hour.ago)

    visit home_path
    frame = find("turbo-frame#home-trends")
    frame.scroll_to(frame)
    within(frame) do
      assert_selector "article svg path.stroke-trend", count: 2
      find("a[href='#{play_path(list: single.id)}']").click
    end

    assert_current_path play_path(list: single.id)
    assert_selector "[data-practice-save-url-value]"
  end
end
