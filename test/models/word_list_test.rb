require "test_helper"

class WordListTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @pack = @user.packs.create!(name: "自作")
  end

  test "reads words from tab and comma separated lines, defaulting the input to the display" do
    list = @pack.word_lists.create!(name: "基本", words_text: "ls\tls\t一覧\n\npwd, pwd, \"今いる, 場所\"\nこんにちは\n")
    assert_equal [["ls", "ls", "一覧"], ["pwd", "pwd", "今いる, 場所"], ["こんにちは", "こんにちは", ""]],
      list.words.map { |w| [w.display, w.input, w.annotation] }
    assert_equal @user, list.user
  end

  test "needs a name and at least one word" do
    list = @pack.word_lists.new(name: "", words_text: "")
    assert_not list.valid?
    assert_includes list.errors.full_messages, "単語を1つ以上入力してください"
  end

  test "best compares the current word count, accuracy first and then time" do
    list = @pack.word_lists.create!(name: "基本", words_text: "a\nb")
    fast_sloppy = record(list, time_ms: 1000, accuracy: 90)
    slow_clean = record(list, time_ms: 3000, accuracy: 100)
    record(list, time_ms: 500, accuracy: 100, word_count: 5)
    record(list, time_ms: 100, accuracy: 100, mode: "recall")
    assert_equal slow_clean, list.reload.best
    assert_equal [slow_clean, fast_sloppy], list.comparable_records
  end

  test "editing the words replaces them" do
    list = @pack.word_lists.create!(name: "基本", words_text: "a\nb")
    list.update!(words_text: "c")
    assert_equal ["c"], list.reload.words.map(&:display)
  end

  private
    def record(list, time_ms:, accuracy:, word_count: 2, mode: nil)
      list.practice_records.create!(user: @user, time_ms:, accuracy:, word_count:, mode:, mistakes: 0)
    end

  test "a pack's lists have different names, and a user's packs too, case aside (typle-r's validateList)" do
    user = users(:one)
    pack = user.packs.create!(name: "名前")
    pack.word_lists.create!(user:, name: "Basic", words_text: "a")
    copy = pack.word_lists.new(user:, name: " basic ", words_text: "b")
    assert_not copy.valid?
    assert_equal ["同じ名前の単語リストがあります。別の名前を指定してください。"], copy.errors.where(:name).map(&:message)
    assert_not user.packs.new(name: "名前").valid?
  end

  test "following an official pack beside an own pack of its name tells them apart with （2）" do
    user = users(:one)
    name = OfficialCatalog.find("pack-vim-beginner").name
    user.packs.create!(name:)
    assert_equal "#{name}（2）", OfficialCatalog.follow(user, "pack-vim-beginner").name
  end
end
