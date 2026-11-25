# typle-r's WeakWords: per list, the words missed most in its recent runs, and a button to practise just those.
class Home::WeakListsComponent < ApplicationComponent
  delegate :home_t, :home_word_meaning, :practice_name, :link_button, to: :helpers

  def initialize(dashboard:)
    @items = dashboard.weak_lists
  end

  private

  attr_reader :items

  def word_of(item, weak_word) = item.list.words.find { |word| word.input == weak_word.word }

  # The word as it is typed, after its display when the two differ.
  def written(word) = word.display == word.input ? word.input : "#{word.display} #{word.input}"

  def meaning(word) = word.annotation.present? ? home_word_meaning(word.display, word.annotation) : ""
end
