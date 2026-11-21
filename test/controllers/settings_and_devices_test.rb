require "test_helper"

class SettingsAndDevicesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "devices: add, choose, record the device, rename without changing records, delete" do
    post devices_path, params: { device: { name: "HHKB", layout: "US" }, use: "1" }
    device = users(:one).devices.last
    assert_redirected_to devices_path

    list = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 1000, mistakes: 0, accuracy: 100 }
    record = PracticeRecord.last
    assert_equal [device.id.to_s, "HHKB", "US"], [record.device_key, record.device_name, record.device_layout]

    patch device_path(device), params: { device: { name: "HHKB Pro", layout: "US" } }
    assert_equal "HHKB", record.reload.device_name

    post devices_path, params: { device: { name: "hhkb pro", layout: "" } }
    assert_response :unprocessable_entity

    post choose_devices_path, params: { key: "" }
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 1000, mistakes: 0, accuracy: 100 }
    assert_nil PracticeRecord.last.device_key

    delete device_path(device)
    get devices_path
    assert_response :success
  end

  test "the built-in device is used until another is chosen" do
    list = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 1000, mistakes: 0, accuracy: 100 }
    assert_equal ["default", "デフォルト"], [PracticeRecord.last.device_key, PracticeRecord.last.device_name]
  end

  test "interests pick the packs shown, and the switches follow and unfollow" do
    patch interests_path, params: { interests: ["programming", "programming/vim", "language/ko"] }
    assert_equal ["programming", "programming/vim"], users(:one).reload.interests
    get interests_path
    assert_select "input[name='follow[]'][value='pack-vim-beginner']"
    assert_select "input[name='follow[]'][value='pack-korean-basics']", 0

    patch packs_interests_path, params: { shown: ["pack-vim-beginner", "pack-vim"], follow: ["pack-vim-beginner"] }
    assert users(:one).packs.exists?(catalog_id: "pack-vim-beginner")
    patch packs_interests_path, params: { shown: ["pack-vim-beginner"], follow: [] }
    assert_not users(:one).packs.exists?(catalog_id: "pack-vim-beginner")
  end

  test "interest chips are toggle buttons with typle-r's rules: a parent takes its children with it" do
    patch interests_path, params: { interests: ["programming", "programming/vim"] }
    get interests_path
    assert_select "button[name=toggle][value=programming][aria-pressed=true]"
    assert_select "button[name=toggle][value='language'][aria-pressed=false]"
    patch interests_path, params: { toggle: "language/ko" }
    assert_equal ["programming", "programming/vim"], users(:one).reload.interests, "a child needs its parent chosen"
    patch interests_path, params: { toggle: "language" }
    patch interests_path, params: { toggle: "language/ko" }
    assert_equal ["language", "language/ko", "programming", "programming/vim"], users(:one).reload.interests.sort
    patch interests_path, params: { toggle: "language" }
    assert_equal ["programming", "programming/vim"], users(:one).reload.interests, "a parent goes with its children"
  end

  test "ベスト記録 chooses the mode and the order with radio buttons, and the lists with buttons" do
    list = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: list.id, time_ms: 1000, mistakes: 0, accuracy: 100 }
    get rankings_path
    assert_select "[role=radiogroup] button[role=radio][aria-checked=true][tabindex='0']", 2
    assert_select "button[role=radio][aria-checked=false][tabindex='-1'][data-url='/rankings?order=speed']"
    assert_select "button[data-visit-url][data-list-id='#{list.id}']"
  end

  test "practice opens the first list when none is given, as typle-r's usePractice does" do
    first = OfficialCatalog.follow(users(:one), "pack-vim-beginner").word_lists.first
    other = OfficialCatalog.follow(users(:one), "pack-vim").word_lists.first
    post practice_records_path, as: :json, params: { word_list_id: other.id, time_ms: 1000, mistakes: 0, accuracy: 100 }
    get play_path
    assert_select "[data-practice-list-id-value='#{first.id}']"
  end

  test "the display language is kept in a cookie" do
    patch locale_settings_path, params: { locale: "en" }
    get home_path
    assert_select "html[lang=en]"
    patch locale_settings_path, params: { locale: "xx" }
    get home_path
    assert_select "html[lang=en]"
  end
end
