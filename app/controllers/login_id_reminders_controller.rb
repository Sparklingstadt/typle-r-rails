# IDを忘れたとき: the ID is sent to the account's confirmed email.
class LoginIdRemindersController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_login_id_reminder_path, alert: t("errors.rate_limited") }

  def new
  end

  def create
    user = User.accounts.where.not(email_confirmed_at: nil).find_by(email: params[:email].to_s.strip.downcase)
    AccountMailer.login_id_reminder(user).deliver_later if user
    @sent = true
    render :new
  end
end
