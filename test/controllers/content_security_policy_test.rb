require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "a first visit's inline scripts carry the policy's nonce, and it stays through the session" do
    get root_path
    nonce = policy_nonce
    assert nonce.present?, "a browser without a session still gets a nonce"
    assert_select "script:not([src])" do |scripts|
      scripts.each { |script| assert_equal nonce, script["nonce"] }
    end

    get play_path(official: "vim-beginner")
    assert_equal nonce, policy_nonce
    assert_select "script:not([src])" do |scripts|
      scripts.each { |script| assert_equal nonce, script["nonce"] }
    end
  end

  test "scripts are the app's own or carry the nonce" do
    get root_path
    script_src = response.headers["Content-Security-Policy"][/script-src ([^;]+)/, 1]
    assert_no_match(/'unsafe-inline'|'unsafe-eval'|https:/, script_src)
    assert_match(/object-src 'none'/, response.headers["Content-Security-Policy"])
  end

  private
    def policy_nonce = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
end
