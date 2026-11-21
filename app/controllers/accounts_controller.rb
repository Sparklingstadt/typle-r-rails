# The signed-in account, shown in the general settings as typle-r shows it (AccountSettings, SessionSettings): mailing
# the confirmation of its address again, changing its password and signing out of every device.
class AccountsController < ApplicationController
  require_account

  def show
    redirect_to general_settings_path(anchor: "account")
  end

  # typle-r's change-password: the current password and a new one; the other devices are signed out.
  def update_password
    unless account.password_digest.present? && account.authenticate(params[:current_password].to_s)
      return redirect_to general_settings_path(anchor: "account"), alert: helpers.tt("errors.wrongPassword")
    end
    if account.update(password: params[:password].to_s)
      account.sessions.where.not(id: Current.session.id).destroy_all
      redirect_to general_settings_path(anchor: "account"), notice: helpers.tt("auth.settings.changed")
    else
      redirect_to general_settings_path(anchor: "account"), alert: account.errors.full_messages.to_sentence
    end
  end

  # typle-r's resend-verification.
  def resend_verification
    if account.email_confirmed?
      redirect_to general_settings_path(anchor: "account"), notice: helpers.tt("auth.settings.alreadyVerified")
    else
      AccountMailer.email_confirmation(account).deliver_later if account.email
      redirect_to general_settings_path(anchor: "account"), notice: helpers.tt("auth.settings.resent")
    end
  end

  # typle-r's すべての端末からログアウト: every session of the account, this one included.
  def sign_out_everywhere
    user = account
    terminate_session
    user.sessions.destroy_all
    redirect_to root_path, status: :see_other
  end
end
