require "test_helper"

# typle-r's pages kept for links handed out: a shared practice result, the licenses, an ended pack share, the gallery
# and the address confirmation link.
class KeptPagesTest < ActionDispatch::IntegrationTest
  test "a shared result shows what its link carries, and a broken link says so" do
    get shared_result_path(n: "Vim  コマンド", t: "12.345", a: "98", w: "38", s: "250", m: "recall")
    assert_response :success
    assert_select "h1", "「Vim コマンド」の練習記録"
    assert_select "dd", /12.35/
    assert_select "meta[name=robots][content='noindex, follow']"
    get shared_result_path(n: "Vim", t: "1", a: "101", w: "3")
    assert_select "h1", "記録を表示できません"
  end

  test "the licenses list the bundle, and their texts come as one file" do
    get licenses_path
    assert_response :success
    assert_select "li[data-search*='rails']"
    get licenses_path(format: :txt)
    assert_match "MIT", response.body
  end

  test "an ended pack share, the gallery and the confirmation link" do
    get shared_pack_path("abc")
    assert_select "[role=status]", "この共有は終了しました。"
    get "/gallery"
    assert_redirected_to "/catalog"
    user = users(:one)
    user.update!(email: "one@example.com", email_confirmed_at: nil)
    get verify_email_path(token: user.generate_token_for(:email_confirmation))
    assert user.reload.email_confirmed?
  end

  test "the settings are at typle-r's addresses: /settings is 一般 and /input is 入力, open to anyone" do
    get "/settings"
    assert_response :success
    assert_select "a[href='/settings'][aria-current]"
    get "/input"
    assert_response :success
    assert_select "a[href='/input'][aria-current]"
    get "/settings/general"
    assert_redirected_to "/settings"
  end
end
