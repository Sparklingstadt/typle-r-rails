require "test_helper"

class PackFilesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "a pack is exported as typle-r's pack file and imported back as a new pack" do
    pack = OfficialCatalog.follow(users(:one), "pack-vim-beginner")
    get export_pack_path(pack)
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal "typle-pack", data["format"]
    assert_equal 1, data["version"]
    assert_equal pack.name, data.dig("pack", "name")
    assert_equal pack.word_lists.size, data["lists"].size
    assert_equal pack.word_lists.first.words.first.input, data["lists"][0]["words"][0]["input"]
    assert response.body.end_with?("\n")

    file = Rack::Test::UploadedFile.new(StringIO.new(response.body), "application/json", original_filename: "x.typle-pack.json")
    assert_difference -> { users(:one).packs.count } do
      post import_packs_path, params: { file: }
    end
    imported = Pack.last
    assert_equal "#{pack.name}（2）", imported.name, "a name a pack has gets （2）"
    assert_not imported.followed?
    assert_equal pack.word_lists.map { |l| l.words.map(&:input) }, imported.word_lists.map { |l| l.words.map(&:input) }
  end

  test "a file that is not a pack file is refused" do
    file = Rack::Test::UploadedFile.new(StringIO.new(+'{"format":"other"}'), "application/json", original_filename: "x.json")
    assert_no_difference -> { Pack.count } do
      post import_packs_path, params: { file: }
    end
    assert_redirected_to packs_path
  end

  test "duplicating a pack and a list copies the words without records" do
    pack = OfficialCatalog.follow(users(:one), "pack-vim-beginner")
    post copy_pack_path(pack)
    copy = Pack.last
    assert_redirected_to packs_path(pack: copy.id)
    assert_equal "#{pack.name}（コピー）", copy.name
    assert copy.editable?, "a copy of a followed pack is the user's own"
    assert_equal pack.word_lists.size, copy.word_lists.size

    list = copy.word_lists.first
    list.practice_records.create!(user: users(:one), time_ms: 100, accuracy: 100, mistakes: 0, word_count: list.words.size)
    post copy_word_list_path(list)
    duplicate = copy.word_lists.reload.last
    assert_equal "#{list.name}（コピー）", duplicate.name
    assert_equal list.words.map(&:input), duplicate.words.map(&:input)
    assert_empty duplicate.practice_records
    post copy_word_list_path(list)
    assert_equal "#{list.name}（コピー2）", copy.word_lists.reload.last.name
  end

  test "a list of a followed pack cannot be duplicated inside it" do
    pack = OfficialCatalog.follow(users(:one), "pack-vim-beginner")
    assert_no_difference -> { WordList.count } do
      post copy_word_list_path(pack.word_lists.first)
    end
  end

  test "a closed pack's lists come into its frame, and alone lead back to the packs page" do
    sign_in_as users(:one)
    pack = users(:one).packs.create!(name: "Git")
    list = pack.word_lists.create!(user: users(:one), name: "基本", words_text: "git")
    other = users(:two).packs.create!(name: "他人")

    get lists_pack_path(pack), headers: { "Turbo-Frame" => "pack_#{pack.id}-lists" }
    assert_response :success
    assert_select "turbo-frame#pack_#{pack.id}-lists[target=_top] ul > li[data-list-id='#{list.id}']"
    assert_select "svg symbol#icon-sprite-keyboard"
    get lists_pack_path(pack)
    assert_redirected_to packs_path(open: pack.id)
    get lists_pack_path(other), headers: { "Turbo-Frame" => "pack_#{other.id}-lists" }
    assert_response :not_found
  end
end
