require "test_helper"

class FlowTest < ActionDispatch::IntegrationTest
  test "guests see the landing page, the catalog and can practise an official list" do
    get root_path
    assert_response :success
    get catalog_index_path
    assert_response :success
    get catalog_path("pack-vim-beginner")
    assert_response :success
    get play_path(official: "vim-beginner")
    assert_response :success
    assert_select "[data-controller=practice]"
    assert_select "[data-practice-save-url-value]", false
  end

  test "guests keep their own data in this browser, apart from accounts" do
    get home_path
    assert_response :success
    assert_not User.exists?(guest: true), "opening a page makes no guest"

    post follow_catalog_path("pack-vim-beginner")
    guest = User.find_by(guest: true)
    assert guest, "the first thing saved makes the guest"
    list = guest.word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 1000, mistakes: 0, accuracy: 100 }
    assert_response :created
    assert_equal 1, guest.practice_records.count

    post session_path, params: { login_id: "one", password: "password123" }
    get packs_path
    assert_select "[data-pack-id] h3", { text: "Vimコマンド（2）", count: 0 }, "the account does not see the guest's packs"

    delete session_path
    get packs_path
    assert_select "[data-pack-id] h3", "Vimコマンド（2）"
    assert_equal 1, User.where(guest: true).count, "signing out goes back to the same guest data"
  end

  test "pages open for a browser without a guest, and none is made" do
    [home_path, play_path, packs_path, new_pack_path, create_list_path, words_path, practice_records_path, rankings_path,
     devices_path, interests_path, catalog_index_path, input_settings_path].each do |path|
      get path
      assert_response :success, path
    end
    assert_not User.exists?(guest: true)
    assert_nil cookies["guest_id"]
  end

  test "new guests are limited by address" do
    store = ActionController::Base.cache_store
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
    stub_const(Authentication, :GUEST_LIMIT, 2) do
      3.times do
        cookies.delete("guest_id")
        post choose_devices_path, params: { key: "" }
      end
      assert_redirected_to root_path
      assert_equal 2, User.where(guest: true).count

      cookies.delete("guest_id")
      post practice_records_path, as: :json, params: { word_list_id: 1 }
      assert_response :too_many_requests
    end
  ensure
    ActionController::Base.cache_store = store
  end

  test "registering signs in" do
    post registration_path, params: { user: { login_id: "newbie", password: "password123" } }
    assert_response :unprocessable_entity
    assert_select "#signup-email-error", "メールアドレスの形式が正しくありません。"
    post registration_path, params: { user: { login_id: "new.bie", email: "new@example.com", password: "short" } }
    assert_select "#signup-login-id-error", /半角英数字/
    assert_select "#signup-password-error", "パスワードは10〜72文字で入力してください。"
    post registration_path, params: { user: { login_id: "newbie", email: "new@example.com", password: "password123" } }
    assert_response :success
    assert_select "[role=status]", "登録して、ログインしました。"
    get home_path
    assert_response :success
  end

  test "a signed-in user follows a pack, practises, saves a record and sees it" do
    sign_in_as users(:one)
    get play_path
    assert_select "h1", "どれから練習しますか？"

    post follow_catalog_path("pack-vim-beginner", practice: 1)
    list = users(:one).word_lists.first
    assert_redirected_to play_path(list: list.id)
    get play_path(list: list.id)
    assert_response :success

    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 12345, mistakes: 2, accuracy: 97.5,
      missed: [{ word: list.words.first.input, count: 2 }] }
    assert_response :created
    record = PracticeRecord.last
    assert_equal({ "id" => record.id, "url" => practice_record_path(record), "comparison" => { "rank" => 1, "kind" => "firstForList" } }, response.parsed_body)
    assert_equal list.words.size, record.word_count

    get practice_record_path(record)
    assert_select "h1", list.full_name
    get home_path
    assert_select "h2", list.full_name
    get rankings_path
    assert_response :success
    get practice_records_path(list: list.id)
    assert_response :success
  end

  test "a record with an unknown mode, or a handwriting record of an unmarked list, is refused" do
    sign_in_as users(:one)
    list = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 100, mistakes: 0, accuracy: 100, mode: "writing" }
    assert_response :unprocessable_entity
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 100, mistakes: 0, accuracy: 100, mode: "fast" }
    assert_response :unprocessable_entity
  end

  test "handwriting: a marked list offers the mode, and its records are kept apart" do
    sign_in_as users(:one)
    pack = OfficialCatalog.follow(users(:one), "pack-korean-handwriting-beginner-words-1")
    list = pack.word_lists.first
    assert_equal "ko", list.writing_language
    get play_path(list: list.id, mode: "writing")
    assert_select "[data-controller=writing][data-writing-language-value=ko]"
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 5000, mistakes: 1, accuracy: 90, mode: "writing" }
    assert_response :created
    assert_nil list.best
    assert_equal "writing", list.best("writing").mode
    get rankings_path(mode: "writing")
    assert_select "h2", list.full_name
  end

  test "another user's list cannot be practised or recorded" do
    other = OfficialCatalog.follow(users(:two), "pack-vim-beginner").word_lists.first
    sign_in_as users(:one)
    get play_path(list: other.id)
    assert_response :not_found
    post practice_records_path, as: :json, params: { word_list_id: other.id, time_ms: 100, mistakes: 0, accuracy: 100 }
    assert_response :not_found
  end

  test "own packs: create, add a list, edit, export, import and delete" do
    sign_in_as users(:one)
    post packs_path, params: { pack: { name: "シェル" } }
    pack = Pack.last
    post pack_word_lists_path(pack), params: { word_list: { name: "基本", words_text: "ls\tls\t一覧" } }
    assert_redirected_to packs_path(pack: pack.id)
    list = pack.word_lists.first
    patch word_list_path(list), params: { word_list: { name: "基本", words_text: "ls\npwd" } }
    assert_equal 2, list.reload.words.count
    patch word_list_path(list), params: { word_list: { name: "基本", words_text: "" } }
    assert_response :unprocessable_entity
    assert_equal 2, list.reload.words.count

    get export_word_list_path(list)
    exported = response.body.force_encoding("UTF-8")
    assert_equal "\uFEFFinput,display,annotation\r\n\"ls\",\"ls\",\"\"\r\n\"pwd\",\"pwd\",\"\"\r\n", exported, "typle-r's CSV"

    # An exported file is read back by its header.
    file = Rack::Test::UploadedFile.new(StringIO.new(exported.delete_prefix("\uFEFF")), "text/csv", original_filename: "書き出し.csv")
    post import_packs_path, params: { file: }
    assert_equal %w[ls pwd], Pack.last.word_lists.first.words.map(&:input)

    file = Rack::Test::UploadedFile.new(StringIO.new(+"cat,cat,中身を表示\n"), "text/csv", original_filename: "取り込み.csv")
    post import_packs_path, params: { file: }
    imported = Pack.last
    assert_equal "取り込み", imported.name
    assert_equal ["cat"], imported.word_lists.first.words.map(&:input)

    delete pack_path(pack)
    assert_not Pack.exists?(pack.id)
  end

  test "followed packs cannot be edited" do
    sign_in_as users(:one)
    pack = OfficialCatalog.follow(users(:one), "pack-vim-beginner")
    get edit_word_list_path(pack.word_lists.first)
    assert_redirected_to packs_path(pack: pack.id)
  end

  test "weak review practises only the weak words and is kept on the list" do
    sign_in_as users(:one)
    list = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    list.practice_records.create!(user: users(:one), time_ms: 100, accuracy: 90, mistakes: 1, word_count: list.words.size,
      missed: [{ "word" => list.words.second.input, "count" => 1 }])
    get play_path(list: list.id, review: "weak")
    words = JSON.parse(css_select("[data-controller=practice]").first["data-practice-words-value"])
    assert_equal [list.words.second.input], words.map { |w| w["input"] }

    post weak_review_word_list_path(list), as: :json, params: { missed: [] }
    assert_response :no_content
    assert list.reload.weak_reviewed_at
  end

  test "settings are saved" do
    sign_in_as users(:one)
    patch settings_path, params: { user: { ignore_accents: "1", ignore_case: "1" } }
    assert_equal "1", cookies[:ignore_accents], "kept in this browser, as typle-r keeps it"
    get play_path(official: "vim-beginner")
    assert_match "\"ignoreAccents\":true", response.body.gsub("&quot;", "\"")
  end
end
