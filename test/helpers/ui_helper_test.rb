require "test_helper"

class UiHelperTest < ActionView::TestCase
  include LucideRails::RailsHelper
  # The flash alert, as the controller gives it to the views.
  attr_accessor :alert

  test "the header names the page, unless it has named itself, and the alert follows it once" do
    self.alert = "保存できませんでした"
    html = page_header("単語リスト", "説明")

    assert_equal "単語リスト", content_for(:title)
    assert_includes html, "保存できませんでした"
    assert_not_includes page_header("もう一度"), "保存できませんでした", "the alert is shown once"
    assert_equal "単語リスト", content_for(:title)
  end
end
