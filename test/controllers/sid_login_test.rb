require "test_helper"

# typle-r's Sparklingstadt ID login (tests/sidLogin.test.cjs, the E2E sid-login.spec.ts): the OpenID Connect flow, the
# account it opens, its refusals and the prompt=login after a sign-out.
class SidLoginTest < ActionDispatch::IntegrationTest
  test "the profile: the sub and the ID's name, or its address before @" do
    assert_equal({ sub: "abc123", name: "Alice" }, SidLogin.profile(sub: "abc123", email: "a@example.com", email_verified: true, name: "  Alice "))
    assert_equal({ sub: "abc123", name: "a" }, SidLogin.profile(sub: "abc123", email: "a@example.com", email_verified: true, name: "  "))
    assert_equal({ sub: "abc123", name: "a" }, SidLogin.profile("sub" => "abc123", "email" => "a@example.com", "email_verified" => true))
  end

  test "the profile refuses an address that is not confirmed, and a sub not of its form" do
    [false, nil, "true", 1].each do |verified|
      assert_raises(SidLogin::Refused, verified.inspect) { SidLogin.profile(sub: "abc123", email: "a@example.com", email_verified: verified) }
    end
    ["ABC", "a-b", "", "a" * 65, 123, nil].each do |sub|
      assert_raises(SidLogin::Refused, sub.inspect) { SidLogin.profile(sub:, email: "a@example.com", email_verified: true) }
    end
    assert_equal "a" * 64, SidLogin.profile(sub: "a" * 64, email_verified: true)[:sub]
  end

  test "the login asks for the code with PKCE (S256), state and nonce, and the scope openid email profile" do
    query = sign_in_with_sid
    assert_equal "code", query["response_type"]
    assert_equal SidServerTestHelper::CLIENT_ID, query["client_id"]
    assert_equal "openid email profile", query["scope"]
    assert_equal "http://www.example.com/auth/sid/callback", query["redirect_uri"]
    assert_equal "S256", query["code_challenge_method"]
    assert query["code_challenge"].present? && query["state"].present? && query["nonce"].present?
    assert_nil query["prompt"], "no sign-out yet"
  end

  test "a first login makes the ID's own account, and the next opens it again" do
    assert_difference(-> { User.count }) { sign_in_with_sid(sub: "abc123", origin: "/records") }
    assert_redirected_to "/records"
    user = User.find_by!(sid_sub: "abc123")
    assert_equal ["Sid abc123", nil, nil], [user.name, user.login_id, user.github_uid]
    assert_not user.saved_data?, "the first login saves nothing"

    get home_path
    assert_select "[title='Sid abc123']"
    assert_select "span", "Sparklingstadt IDでログイン中"

    delete session_path
    assert_no_difference(-> { User.count }) { sign_in_with_sid(sub: "abc123", claims: { name: nil }) }
    assert_redirected_to "/home"
    assert_equal "abc123", user.reload.name, "without a name, the address before @"
  end

  test "an ID without a name or an address is a Sparklingstadt ID user" do
    sign_in_with_sid(sub: "noname", claims: { name: nil, email: nil })
    get home_path
    assert_select "[title='Sparklingstadt IDユーザー']"
  end

  test "a linked ID opens the account it is linked to" do
    users(:two).update!(sid_sub: "linked1")
    assert_no_difference(-> { User.count }) { sign_in_with_sid(sub: "linked1") }
    assert_redirected_to "/home"
    assert_equal users(:two), Session.order(:id).last.user
    get home_path
    assert_select "span", "GitHubでログイン中"
  end

  test "an address that is not confirmed, or a sub not of its form, is refused" do
    [{ sub: "abc123", claims: { email_verified: false } }, { sub: "abc123", claims: { email_verified: "true" } },
     { sub: "abc123", claims: { email_verified: nil } }, { sub: "Not-A-Sub" }].each do |login|
      assert_no_difference(-> { User.count }) { sign_in_with_sid(**login) }
      assert_redirected_to "/signin?error=1"
      assert_nil cookies[:session_id].presence, login.inspect
    end
    follow_redirect!
    assert_select "[role=alert]", "ログインできませんでした。もう一度お試しください。"
  end

  test "an ID token that does not verify is a failed login" do
    [{ key: SidServerTestHelper::OTHER_KEY }, { claims: { aud: "another-client" } }, { claims: { iss: "https://evil.example" } },
     { claims: { exp: 1.minute.ago.to_i } }, { claims: { nonce: "another-nonce" } }, { alg: :HS256, key: ENV["SID_CLIENT_SECRET"] }].each do |login|
      assert_no_difference(-> { User.count }) { sign_in_with_sid(**login) }
      assert_redirected_to "/signin?error=1", login.inspect
      assert_nil cookies[:session_id].presence, login.inspect
    end
  end

  test "a callback whose state is not this browser's is refused" do
    stub_sid_discovery
    post "/auth/sid"
    get "/auth/sid/callback", params: { code: "the-code", state: "forged" }
    assert_redirected_to "/signin?error=1"
    assert_not User.exists?(sid_sub: "abc123")
  end

  test "an ID server that cannot be reached is a failed login, kept to the page it started from" do
    stub_request(:get, "#{SidServerTestHelper::ISSUER}/.well-known/openid-configuration").to_timeout
    post "/auth/sid", params: { origin: "/records" }
    assert_redirected_to "/signin?error=1&returnTo=%2Frecords"
  end

  test "when the link cannot be read the login fails, and no empty account is opened" do
    find_by = User.method(:find_by)
    User.define_singleton_method(:find_by) do |*args, **options|
      raise ActiveRecord::ConnectionNotEstablished, "down" if args.first.is_a?(Hash) && args.first.key?(:sid_sub) || options.key?(:sid_sub)
      find_by.call(*args, **options)
    end
    assert_no_difference(-> { User.count }) { sign_in_with_sid(sub: "abc123") }
    assert_redirected_to "/signin?error=1"
    assert_nil cookies[:session_id].presence
  ensure
    User.singleton_class.remove_method(:find_by)
  end

  test "after a sign-out the next login asks for the password (prompt=login), and a login that succeeds forgets it" do
    sign_in_with_sid
    assert_nil cookies[SidLogin::RELOGIN_COOKIE]
    delete session_path
    assert_equal "1", cookies[SidLogin::RELOGIN_COOKIE]
    relogin = response.headers["Set-Cookie"].to_s.lines.find { _1.start_with?(SidLogin::RELOGIN_COOKIE) } ||
              Array(response.headers["Set-Cookie"]).find { _1.start_with?(SidLogin::RELOGIN_COOKIE) }
    assert_match(/httponly/i, relogin)
    assert_match(/samesite=lax/i, relogin)
    assert_match(/expires=/i, relogin)
    assert_no_match(/secure/i, relogin, "not over http")

    query = sign_in_with_sid
    assert_equal "login", query["prompt"]
    assert_redirected_to "/home"
    assert cookies[SidLogin::RELOGIN_COOKIE].blank?, "removed by the login"
    assert_nil sign_in_with_sid["prompt"]
  end

  test "a failed login keeps the cookie, and signing out of every device leaves it too" do
    sign_in_with_sid
    delete sessions_account_path
    assert_equal "1", cookies[SidLogin::RELOGIN_COOKIE]
    sign_in_with_sid(claims: { email_verified: false })
    assert_equal "1", cookies[SidLogin::RELOGIN_COOKIE]
  end

  test "the cookie is Secure over https" do
    https!
    sign_in_as users(:one)
    delete session_path
    relogin = Array(response.headers["Set-Cookie"]).flat_map { _1.to_s.lines }.find { _1.start_with?(SidLogin::RELOGIN_COOKIE) }
    assert_match(/; secure/i, relogin)
  end
end
