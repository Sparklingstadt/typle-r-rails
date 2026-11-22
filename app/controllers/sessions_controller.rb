# typle-r's sign-in page (Sparklingstadt ID and GitHub, started by OmniAuth at /auth/sid and /auth/github) and the
# sign-out.
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new local]

  # The made-up login of development on this machine, as typle-r's authorizeLocal (LOCAL_DEVELOPMENT_LOGIN=1, only in
  # development, only from this machine): it opens the demo account db/seeds.rb makes.
  def self.local_login?(request)
    Rails.env.development? && ENV["LOCAL_DEVELOPMENT_LOGIN"] == "1" && request.local?
  end

  def new
    @local_login = self.class.local_login?(request)
  end

  def local
    user = User.accounts.find_by(login_id: "demo")
    return redirect_to new_session_path(error: 1) unless user
    terminate_session if signed_in?
    start_new_session_for user
    redirect_to after_authentication_url
  end

  def destroy
    terminate_session
    remember_signed_out
    redirect_to root_path, status: :see_other, notice: t(".signed_out")
  end
end
