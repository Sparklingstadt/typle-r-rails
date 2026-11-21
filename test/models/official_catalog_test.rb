require "test_helper"

class OfficialCatalogTest < ActiveSupport::TestCase
  test "groups the official lists into packs with typle-r's catalog ids" do
    vim = OfficialCatalog.find("pack-vim-beginner")
    assert_equal "Vimコマンド（2）", vim.name, "the second pack of the same name, as typle-r names it"
    assert_equal %w[初級 中級 上級], vim.lists.map(&:level)
    assert_equal 269, OfficialCatalog.packs.sum { |pack| pack.lists.size }
    assert OfficialCatalog.find("pack-english-basic-words")
  end

  test "following copies the pack once, as read-only" do
    user = users(:one)
    pack = OfficialCatalog.follow(user, "pack-vim-beginner")
    assert pack.followed?
    assert_not pack.editable?
    assert_equal 3, pack.word_lists.count
    assert_equal "vim-beginner", pack.word_lists.first.origin_list_id
    assert_no_difference(-> { Pack.count }) { OfficialCatalog.follow(user, "pack-vim-beginner") }
  end
end
