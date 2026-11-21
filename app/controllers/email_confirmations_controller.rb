class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])
    if user
      user.update!(email_confirmed_at: Time.current)
      redirect_to(signed_in? ? general_settings_path(anchor: "account") : new_session_path, notice: t(".confirmed"))
    else
      redirect_to root_path, alert: t(".invalid")
    end
  end
end
