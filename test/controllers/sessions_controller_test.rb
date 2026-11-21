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
end
