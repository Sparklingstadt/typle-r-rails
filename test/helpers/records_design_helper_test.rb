require "test_helper"

class RecordsDesignHelperTest < ActionView::TestCase
  include RecordsDesignHelper
  include ApplicationHelper

  test "accuracy is written as typle-r writes it" do
    assert_equal "100%", format_accuracy(100)
    assert_equal "97.7%", format_accuracy(97.66)
    assert_equal "—", format_accuracy(nil)
  end

  test "the clock is written as the browser writes it in each language (Intl, 2-digit hour and minute)" do
    afternoon = Time.zone.local(2026, 11, 21, 14, 5)
    morning = Time.zone.local(2026, 11, 21, 2, 35)
    assert_equal "14:05", I18n.with_locale(:ja) { records_clock(afternoon) }
    assert_equal "02:05 PM", I18n.with_locale(:en) { records_clock(afternoon) }
    assert_equal "上午02:35", I18n.with_locale(:"zh-Hant") { records_clock(morning) }
    assert_equal "14:05", I18n.with_locale(:"zh-Hans") { records_clock(afternoon) }
  end
end
