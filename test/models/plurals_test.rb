require "test_helper"

class PluralsTest < ActiveSupport::TestCase
  test "plural rules survive a reload of the translations, as development reloads them" do
    I18n.reload!
    assert_equal :few, I18n.backend.send(:pluralizer, :ru).call(3)
    assert_equal :many, I18n.backend.send(:pluralizer, :ru).call(5)
    assert_equal :one, I18n.backend.send(:pluralizer, :fr).call(0)
    assert_equal :other, I18n.backend.send(:pluralizer, :ja).call(1)
    assert_equal "1 word", I18n.t("typle.practice.header.wordCount", count: 1, locale: :en)
  end
end
