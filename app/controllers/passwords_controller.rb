# パスワードを忘れたとき: a link to set a new password, sent to the account's confirmed email.
class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("errors.rate_limited") }

  def new
  end

  def create
    # As typle-r: by the ID; the link goes to the account's confirmed email.
    user = User.accounts.where.not(email_confirmed_at: nil).find_by(login_id: params[:login_id].to_s.strip.downcase)
    AccountMailer.password_reset(user).deliver_later if user
    # The same answer whether or not the email is known, so it tells nobody which emails have an account.
    # typle-r says so under the form and stays on the page.
    @sent = true
    render :new
  end

  def edit
  end

  def update
    # typle-r's reset-password: every device is signed out, then this browser signs in with the new password.
    if params[:password].present? && @user.update(password: params[:password])
      @user.sessions.destroy_all
      start_new_session_for(@user)
      redirect_to home_path
    else
      @user.errors.add(:password, :blank) if params[:password].blank?
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for(:password_reset, params[:token])
      redirect_to new_password_path, alert: t("passwords.invalid_link") unless @user
    end
end
