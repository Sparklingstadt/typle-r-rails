require "application_system_test_case"

# The packs page: its rows' icons come from one sprite (UiHelper#with_icon_sprite), and its search finds a pack by a
# word, which the page carries once for all packs (packs-filter).
class PacksSystemTest < ApplicationSystemTestCase
  def follow(catalog_id)
    visit catalog_path(catalog_id)
    click_on I18n.t("design.lists.official.practice")
    assert_selector "[data-practice-save-url-value]"
  end

  test "the rows' icons are drawn from the sprite, and the search finds a pack by a word" do
    follow("pack-vim-beginner")
    follow("pack-english-basic-words")
    vim, english = Pack.order(:id).to_a
    vim_words = vim.word_search_text
    word = english.word_lists.flat_map(&:words).map(&:input).find { |input| input.size > 3 && !vim_words.include?(input.downcase) }

    visit packs_path
    # A sprite icon has its shape: the <use> draws the symbol at the icon's size.
    size = page.evaluate_script(<<~JS)
      (() => { const svg = document.querySelector("li[data-pack-id] svg.lucide-sprite.lucide-chevron-right"); const box = svg.getBoundingClientRect(); return [box.width, svg.querySelector("use").getBBox().width] })()
    JS
    assert_operator size[0], :>, 0
    assert_operator size[1], :>, 0
    assert_equal 1, all("svg symbol#icon-sprite-chevron-right", visible: :all).size

    find("input[type=search][data-packs-filter-target=query]").fill_in(with: word.upcase)
    assert_selector "li[data-pack-id='#{english.id}']"
    assert_no_selector "li[data-pack-id='#{vim.id}']"
    find("input[type=search][data-packs-filter-target=query]").fill_in(with: vim.name.downcase)
    assert_selector "li[data-pack-id='#{vim.id}']"
  end

  test "a closed pack's lists load when it is opened, and their links leave the page" do
    follow("pack-vim-beginner")
    pack = Pack.order(:id).first
    list = pack.word_lists.first

    visit packs_path
    row = find("li[data-pack-id='#{pack.id}']")
    assert_no_selector "li[data-list-id]", visible: :all
    row.find("button[aria-controls='pack-#{pack.id}']").click
    within(row) do
      assert_selector "li[data-list-id='#{list.id}']"
      find("li[data-list-id='#{list.id}'] a[href='#{play_path(list: list.id)}']", match: :first).click
    end

    assert_current_path play_path(list: list.id)
    assert_selector "[data-practice-save-url-value]"
  end

  test "a list in a pack opened after the page is deleted after the confirm dialog" do
    follow("pack-vim-beginner")
    user = Pack.sole.user
    pack = user.packs.create!(name: "Git")
    kept, gone = %w[基本 応用].map { |name| pack.word_lists.create!(user:, name:, words_text: "git") }

    visit packs_path
    row = find("li[data-pack-id='#{pack.id}']")
    row.find("button[aria-controls='pack-#{pack.id}']").click
    within(row) do
      click_on I18n.t("design.lists.row.more_for", name: gone.name)
      click_on I18n.t("design.lists.row.delete")
    end
    within("dialog[open]") { find("[data-confirm-action]").click }

    assert_no_selector "li[data-list-id='#{gone.id}']", visible: :all
    assert_not WordList.exists?(gone.id)
    assert WordList.exists?(kept.id)
  end
end
