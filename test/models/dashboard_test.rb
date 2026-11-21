require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @list = @user.packs.create!(name: "自作").word_lists.create!(name: "基本", words_text: "ls\npwd\ncd")
  end

  test "weak words count the runs a word went wrong in, most first" do
    practise(missed: [{ "word" => "pwd", "count" => 3 }], at: 2.days.ago)
    practise(missed: [{ "word" => "pwd", "count" => 1 }, { "word" => "cd", "count" => 5 }], at: 1.day.ago)
    weak = Dashboard.new(@user).weak_lists.first
    assert_equal %w[pwd cd], weak.words.map(&:word)
    assert_equal [2, 1], weak.words.map(&:runs)
  end

  test "a weak review starts the weak words again from it" do
    practise(missed: [{ "word" => "pwd", "count" => 3 }], at: 2.days.ago)
    @list.update!(weak_reviewed_at: 1.day.ago, weak_review_missed: [{ "word" => "cd", "count" => 1 }])
    assert_equal %w[cd], Dashboard.new(@user).weak_lists.first.words.map(&:word)
  end

  test "words no longer in the list are not weak" do
    practise(missed: [{ "word" => "gone", "count" => 1 }], at: 1.hour.ago)
    assert_empty Dashboard.new(@user).weak_lists
  end

  test "streak counts days in a row up to today or yesterday" do
    now = Time.zone.parse("2026-11-20 12:00")
    [1, 2, 4].each { |days| practise(at: now - days.days) }
    assert_equal 2, Dashboard.new(@user, now:).streak
    practise(at: now - 1.hour)
    assert_equal 3, Dashboard.new(@user, now:).streak
  end

  test "continue list is the list practised last" do
    practise(at: 1.hour.ago)
    assert_equal @list, Dashboard.new(@user).continue_list
  end

  private
    def practise(at:, missed: [])
      @list.practice_records.create!(user: @user, time_ms: 1000, accuracy: 100, word_count: 3, mistakes: 0, missed:, practiced_at: at)
    end
end
