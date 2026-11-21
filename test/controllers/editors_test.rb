require "test_helper"

# typle-r's editors: a new list from /create into a chosen or new pack, a pack made of existing lists, and the word rows.
class EditorsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "a list made from /create goes into a new pack named after it, or into a chosen pack" do
    post create_list_path, params: { word_list: { name: "シェル", pack_id: "",
      words_rows: [{ display: "ls", input: "", annotation: "一覧", input_type: "command" }, { display: "", input: "", annotation: "" }] } }
    assert_response :unprocessable_entity, "a list with an empty row is not saved, as in typle-r"
    post create_list_path, params: { word_list: { name: "シェル", pack_id: "",
      words_rows: [{ display: "ls", input: "", annotation: "一覧", input_type: "command" }] } }
    list = users(:one).word_lists.last
    assert_redirected_to packs_path(pack: list.pack.id)
    assert_equal "シェル", list.pack.name
    assert_equal [["ls", "ls", "一覧", "command"]], list.words.map { |w| [w.display, w.input, w.annotation, w.input_type] }, "the input defaults to the display"

    post create_list_path, params: { word_list: { name: "Git", pack_id: list.pack_id, words_rows: [{ display: "git status", input: "", annotation: "" }] } }
    assert_equal ["シェル", "Git"], list.pack.reload.word_lists.map(&:name)
  end

  test "editing keeps the rows in their order" do
    pack = users(:one).packs.create!(name: "自作")
    list = pack.word_lists.create!(name: "基本", words_text: "a\nb")
    patch word_list_path(list), params: { word_list: { name: "基本", words_rows: [{ display: "b", input: "", annotation: "" }, { display: "a", input: "A", annotation: "" }] } }
    assert_equal [["b", "b"], ["a", "A"]], list.reload.words.map { |w| [w.display, w.input] }
  end

  test "a pack is made of the user's own lists, and a pack left empty goes" do
    get new_pack_path
    assert_select "[role=alert] a[href=?]", create_list_path # with no lists of their own, typle-r's notice

    one = users(:one).packs.create!(name: "一つ目")
    list = one.word_lists.create!(name: "基本", words_text: "a")
    OfficialCatalog.follow(users(:one), "pack-vim-beginner")
    get new_pack_path
    assert_select "input[name='list_ids[]']", 1, "followed lists cannot be moved"

    post packs_path, params: { pack: { name: "まとめ", description: "説明" }, list_ids: [list.id] }
    pack = users(:one).packs.find_by!(name: "まとめ")
    assert_redirected_to packs_path(pack: pack.id)
    assert_equal [list], pack.word_lists.to_a
    assert_not Pack.exists?(one.id)
  end

  test "a saved run answers with its rank and how it compares, for the result drawn in place" do
    list = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 9000, mistakes: 1, accuracy: 95 }
    assert_equal({ "rank" => 1, "kind" => "firstForList" }, response.parsed_body["comparison"])
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 8000, mistakes: 0, accuracy: 100 }
    assert_equal({ "rank" => 1, "kind" => "best", "difference" => -1.0 }, response.parsed_body["comparison"])
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 9500, mistakes: 3, accuracy: 90 }
    assert_equal({ "rank" => 3, "kind" => "behind", "previous" => { "time" => 8.0, "accuracy" => 100.0 } }, response.parsed_body["comparison"])
    get play_path(list: list.id, highlight: PracticeRecord.last.id)
    assert_select "#best-records"
    assert_select "#practice-aside"
  end

  test "the list editor moves a list to another pack, and a pack left empty goes" do
    sign_in_as users(:one)
    from = users(:one).packs.create!(name: "元")
    list = from.word_lists.create!(user: users(:one), name: "移す", words_text: "ls")
    to = users(:one).packs.create!(name: "先")
    get edit_word_list_path(list)
    assert_select "select[name='word_list[pack_id]'] option[selected][value=?]", from.id.to_s
    assert_select "#word_list_pack_deleted[hidden]"
    patch word_list_path(list), params: { word_list: { pack_id: to.id, name: "移す", words_rows: [{ display: "ls" }] } }
    assert_redirected_to packs_path(open: to.id, list: list.id)
    assert_equal to, list.reload.pack
    assert_not Pack.exists?(from.id), "the pack left without lists is deleted"
    follow_redirect!
    assert_select "[data-list-id='#{list.id}'][data-controller=row-highlight]"
    assert_select "[role=status]", "「移す」を更新しました。"
  end

  test "deleting asks in typle-r's dialog, with what the list holds and its CSV export" do
    sign_in_as users(:one)
    pack = users(:one).packs.create!(name: "一つ")
    list = pack.word_lists.create!(user: users(:one), name: "消す", words_text: "ls")
    get packs_path(open: pack.id)
    assert_select "dialog#confirm-dialog"
    form = css_select("form[action='#{word_list_path(list)}'][data-turbo-confirm]").first
    assert_equal "「消す」を削除しますか？", form["data-turbo-confirm"]
    assert_equal "単語リストを削除します。 パック「一つ」も削除されます。 この操作は取り消せません。", form["data-confirm-description"]
    assert_includes form["data-confirm-details"], export_word_list_path(list)
  end

  test "the pack editor saves a category, tags and the order of the lists" do
    sign_in_as users(:one)
    pack = users(:one).packs.create!(name: "順番")
    first = pack.word_lists.create!(user: users(:one), name: "一", words_text: "a")
    second = pack.word_lists.create!(user: users(:one), name: "二", words_text: "b")
    get edit_pack_path(pack)
    assert_select "[data-controller=label-picker]", 2
    assert_select "input[name='list_ids[]']", 2
    patch pack_path(pack), params: { pack: { name: "順番", category: " Shell ", tags: ["Linux", "linux", "", "Bash"] }, list_ids: [second.id, first.id] }
    assert_redirected_to packs_path(pack: pack.id)
    pack.reload
    assert_equal "Shell", pack.category
    assert_equal %w[Linux Bash], pack.tags
    assert_equal %w[二 一], pack.word_lists.map(&:name)
    patch pack_path(pack), params: { pack: { name: "順番", category: "", tags: [""] } }
    assert_nil pack.reload[:category]
    assert_empty pack[:tags]
  end
end
