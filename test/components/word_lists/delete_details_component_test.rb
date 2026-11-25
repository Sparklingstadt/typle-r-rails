require "test_helper"

class WordLists::DeleteDetailsComponentTest < ViewComponent::TestCase
  setup do
    user = users(:one)
    @list = user.packs.create!(name: "Git").word_lists.new(user:, name: "基本")
    @list.words.build([{ display: "a", input: "a" }, { display: "b", input: "b" }])
    @list.save!
  end

  test "what deleting the list removes, and its export to keep the words" do
    @list.practice_records.create!(user: @list.user, time_ms: 1000, mistakes: 0, accuracy: 100, word_count: 2, practiced_at: 1.hour.ago)
    render_inline(WordLists::DeleteDetailsComponent.new(list: @list, records: @list.practice_records.to_a))

    assert_selector "dd", text: "基本"
    assert_selector "dd", text: I18n.t("typle.wordLists.delete.wordCount", count: 2)
    assert_selector "a[href='/word_lists/#{@list.id}/export'][data-turbo=false]"
    assert_not rendered_content.end_with?("\n"), "it goes into a data attribute as it is"
  end

  test "a list without records says so" do
    render_inline(WordLists::DeleteDetailsComponent.new(list: @list, records: []))

    assert_text I18n.t("typle.wordLists.delete.noRecords")
  end
end
