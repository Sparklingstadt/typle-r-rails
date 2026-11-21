require "test_helper"

class AccountRecoveryTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = users(:one)
    @user.update!(email: "one@example.com", email_confirmed_at: Time.current)
  end

  test "a password is reset by a link sent to the confirmed email" do
    assert_enqueued_emails(1) { post passwords_path, params: { login_id: "ONE" } }
    assert_select "[role=status]", I18n.t("typle.auth.forgotPassword.sent", locale: :ja)
    token = @user.generate_token_for(:password_reset)
    get edit_password_path(token:)
    assert_response :success
    put password_path(token:), params: { password: "brand-new-pass" }
    assert_redirected_to home_path, "signed in with the new password, as typle-r does"
    assert @user.reload.authenticate("brand-new-pass")
    get edit_password_path(token:)
    assert_response :success, "the form opens for any link, as typle-r's"
    put password_path(token:), params: { password: "another-new-pass" }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", "このリンクは使えません。期限が切れたか、すでに使われています。"
    assert_not @user.reload.authenticate("another-new-pass"), "the link works once"
  end

  test "an unknown ID gets the same answer and no mail" do
    assert_no_enqueued_emails { post passwords_path, params: { login_id: "nobody" } }
    assert_select "[role=status]", I18n.t("typle.auth.forgotPassword.sent", locale: :ja)
  end

  test "a forgotten id is sent to the confirmed email" do
    assert_enqueued_emails(1) { post login_id_reminder_path, params: { email: "one@example.com" } }
    mail = AccountMailer.login_id_reminder(@user).deliver_now
    assert_equal "Typle: ログイン ID のお知らせ", mail.subject
    assert_match "\n\none\n\n", mail.body.to_s, "typle-r's loginIds mail, the ID on a line of its own"
  end

  test "the account is shown in the general settings, confirms its email and changes its password" do
    @user.update!(email: "new@example.com", email_confirmed_at: nil)
    sign_in_as @user
    get account_path
    assert_redirected_to general_settings_path(anchor: "account")
    get general_settings_path
    assert_select "#account-heading"
    assert_select "#sessions-heading"
    assert_enqueued_emails(1) { post verification_account_path }
    get email_confirmation_path(@user.generate_token_for(:email_confirmation))
    assert @user.reload.email_confirmed?

    patch password_account_path, params: { current_password: "wrong", password: "another-pass" }
    assert_not @user.reload.authenticate("another-pass")
    patch password_account_path, params: { current_password: "password123", password: "another-pass" }
    assert_redirected_to general_settings_path(anchor: "account")
    assert @user.reload.authenticate("another-pass")
  end

  test "signing out everywhere ends every session of the account" do
    sign_in_as @user
    @user.sessions.create!
    delete sessions_account_path
    assert_redirected_to root_path
    assert_empty @user.sessions.reload
  end

  test "GitHub sign-in makes an account, then signs in to it" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(provider: "github", uid: "42", info: { nickname: "Octo Cat" })
    get "/auth/github/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:github] }
    user = User.find_by(github_uid: "42")
    assert_equal "octo-cat", user.login_id
    assert_redirected_to home_path
    delete session_path
    assert_no_difference(-> { User.count }) do
      get "/auth/github/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:github] }
    end
  ensure
    OmniAuth.config.test_mode = false
  end
end
