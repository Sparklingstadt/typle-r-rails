# The end of a Sparklingstadt ID or GitHub sign-in.
class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access

  # typle-r's Sparklingstadt ID login: the account linked to the ID's sub (bin/rails "sid:link[...]"), else the
  # account of that sub, made on its first login. An ID the app refuses (its address not confirmed, a sub not of its
  # form), or a link that cannot be read, is a failed login: never an empty account opened in its place.
  def sid
    profile = SidLogin.profile(request.env["omniauth.auth"]&.extra&.raw_info)
    user = User.for_sid!(profile[:sub], name: profile[:name])
    terminate_session if signed_in?
    start_new_session_for user
    cookies.delete(SidLogin::RELOGIN_COOKIE)
    redirect_to return_to(request.env["omniauth.origin"])
  rescue SidLogin::Refused, ActiveRecord::ActiveRecordError => error
    Rails.logger.warn("[auth] Sparklingstadt ID login failed: #{error.class}: #{error.message}")
    failure
  end

  # GitHub. A signed-in account links GitHub to itself; otherwise the account linked to this GitHub user signs in, or a
  # new account is made for it (its ID from the GitHub login, made unique).
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
    # The page the sign-in started from, sent to GitHub's sign-in as its origin.
    redirect_to return_to(request.env["omniauth.origin"]), notice: t(".signed_in", login:)
  end

  # typle-r's sign-in page with ?error=: one message, and the way back kept.
  def failure
    origin = request.env["omniauth.origin"] || params[:origin]
    redirect_to new_session_path(error: 1, **(return_to(origin) == "/home" ? {} : { returnTo: return_to(origin) }))
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
