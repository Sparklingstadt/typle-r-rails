class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("errors.rate_limited") }

  def new
  end

  def create
    user = User.accounts.find_by(login_id: params[:login_id].to_s.strip.downcase)
    if user&.password_digest.present? && user.authenticate(params[:password].to_s)
      start_new_session_for user
      redirect_to after_authentication_url
    else
      # typle-r's signIn.refused, under the form: it does not say whether the ID or the password is wrong.
      @refused = true
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other, notice: t(".signed_out")
  end

end
