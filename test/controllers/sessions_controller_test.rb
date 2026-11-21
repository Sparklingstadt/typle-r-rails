require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "signs in with the id and password, and out" do
    post session_path, params: { login_id: "ONE", password: "password123" }
    assert_redirected_to home_path
    assert cookies[:session_id]

    delete session_path
    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end

  test "a wrong password does not sign in" do
    post session_path, params: { login_id: "one", password: "wrong" }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", "ID かパスワードが違うか、しばらくログインできません。"
    assert_select "input[name=login_id][value=one]"
    assert_nil cookies[:session_id]
  end

  test "sign-in comes back to the page it was opened from, as typle-r's returnTo, and only to this site" do
    get "/play?list=1"
    assert_select "a[href='/signin?returnTo=%2Fplay'][data-return-href='/signin?returnTo=%2Fplay%3Flist%3D1']"
    get "/signin", params: { returnTo: "/records" }
    assert_select "input[type=hidden][name=returnTo][value='/records']"
    assert_select "a[href='/signup?returnTo=%2Frecords']"
    post session_path, params: { login_id: "ONE", password: "password123", returnTo: "/records" }
    assert_redirected_to "/records"
    delete session_path
    post session_path, params: { login_id: "ONE", password: "password123", returnTo: "//evil.example/x" }
    assert_redirected_to "/home"
  end

  test "a page for an account sends to sign-in with the way back" do
    get account_path
    assert_redirected_to "/signin?returnTo=%2Faccount"
  end
end
