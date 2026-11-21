# GitHub sign-in, on when GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET are set (an OAuth App whose callback URL is
# <origin>/auth/github/callback). Without them the GitHub button is not shown.
module GithubLogin
  def self.enabled? = ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"], scope: "read:user" if GithubLogin.enabled?
end
OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.on_failure = ->(env) { OmniauthCallbacksController.action(:failure).call(env) }
