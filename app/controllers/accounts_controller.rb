# The signed-in account, shown in the general settings as typle-r shows it (SessionSettings): signing out of every
# device.
class AccountsController < ApplicationController
  require_account

  def show
    redirect_to general_settings_path(anchor: "sessions")
  end

  # typle-r's すべての端末からログアウト: every session of the account, this one included.
  def sign_out_everywhere
    user = account
    terminate_session
    user.sessions.destroy_all
    remember_signed_out
    redirect_to root_path, status: :see_other
  end
end
