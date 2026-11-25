require "application_system_test_case"

# Typle Handwriting with the field (writing_controller.js and writing.js): a word written in the field moves on as
# soon as it matches; 飛ばす counts a mistake.
class WritingTest < ApplicationSystemTestCase
  test "a written word moves on, a skipped one is counted, and the run ends with its result" do
    visit play_path(official: "chinese-hsk6-handwriting-1-words-1", mode: "writing")
    words = practice_words("writing")
    field = find("[data-writing-target=field]")
    assert_selector "[data-writing-target=display]", text: words[0]["display"]

    field.set(words[0]["display"])
    assert_selector "[data-writing-target=display]", text: words[1]["display"]

    click_on I18n.t("design.practice.writing_skip")
    assert_selector "[data-writing-target=display]", text: words[2]["display"]
    assert_selector "[data-writing-target=mistakes]", text: "1"

    words[2..].each do |word|
      find("[data-writing-target=field]").set(word["display"])
      assert_no_selector "[data-writing-target=display]", text: /\A#{Regexp.escape(word["display"])}\z/, wait: 2 unless word == words.last
    end
    assert_selector "[data-writing-target=result]"
  end
end
