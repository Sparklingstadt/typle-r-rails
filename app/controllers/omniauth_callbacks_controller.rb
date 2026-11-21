# The end of GitHub sign-in. A signed-in account links GitHub to itself; otherwise the account linked to this GitHub
# user signs in, or a new account is made for it (its ID from the GitHub login, made unique).
class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access

  def github
    auth = request.env["omniauth.auth"]
    uid = auth.uid.to_s
    login = auth.info.nickname.to_s
    if signed_in?
      return redirect_to general_settings_path, alert: t(".taken") if User.where.not(id: account.id).exists?(github_uid: uid)
      account.update!(github_uid: uid, github_login: login)
      return redirect_to general_settings_path, notice: t(".linked", login:)
    end
    user = User.find_by(github_uid: uid) || User.create!(login_id: free_login_id(login), github_uid: uid, github_login: login)
    start_new_session_for user
    redirect_to after_authentication_url, notice: t(".signed_in", login:)
  end

  def failure
    redirect_to new_session_path, alert: t(".failed")
  end

  private
    def free_login_id(login)
      base = login.downcase.gsub(/[^a-z0-9_-]/, "-").presence || "github"
      base = base.ljust(3, "_")[0, 28]
      candidate = base
      candidate = "#{base}-#{SecureRandom.alphanumeric(3).downcase}" while User.exists?(login_id: candidate)
      candidate
    end
end
