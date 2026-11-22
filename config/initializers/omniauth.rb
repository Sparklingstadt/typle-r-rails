# The logins, as typle-r has them since v2.59.0: Sparklingstadt ID and GitHub, nothing else.

# GitHub sign-in, on when GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET are set (an OAuth App whose callback URL is
# <origin>/auth/github/callback). Without them the GitHub button is not shown.
module GithubLogin
  def self.enabled? = ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
end

# Sparklingstadt ID (https://id.sparklingstadt.com), the OpenID Connect provider shared by the Sparklingstadt services:
# typle-r's src/server/sidLogin.ts and src/lib/sidLogin.ts. On when SID_ISSUER, SID_CLIENT_ID and SID_CLIENT_SECRET are
# set (a client whose redirect URI is <origin>/auth/sid/callback); without them its button is not shown.
module SidLogin
  # A login the app refuses: the ID's address is not confirmed, or its sub is not of its form.
  class Refused < StandardError; end

  # The cookie that makes the next Sparklingstadt ID login ask for the password (prompt=login): the ID server keeps its
  # own login, so without it a browser signed out of this app would be let straight back in. It is left by a sign-out
  # that went through and removed by a Sparklingstadt ID login that succeeded.
  RELOGIN_COOKIE = "typle-sid-relogin"
  # How long the cookie is kept: typle-r's longest login (SESSION_MAX_AGE).
  RELOGIN_MAX_AGE = 30.days

  # The form of a sub, as typle-r accepts sid:<sub>.
  SUB = /\A[a-z0-9]{1,64}\z/

  # The algorithms an ID token may be signed with: the ID server's keys (JWKS), never the client secret or none.
  ID_TOKEN_ALGORITHMS = %i[RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 EdDSA].freeze

  def self.enabled? = ENV["SID_ISSUER"].present? && ENV["SID_CLIENT_ID"].present? && ENV["SID_CLIENT_SECRET"].present?

  # typle-r's sidProfile: the sub and the name of the account a login opens, from the claims of the ID token (and the
  # userinfo). An ID whose address is not confirmed (email_verified is not true), or whose sub is not of its form, is
  # refused. The name is the ID's name, or its address before @ when that is blank. There is no picture.
  def self.profile(claims)
    claims = claims.to_h.stringify_keys
    raise Refused, "Sparklingstadt ID: the address is not confirmed" unless claims["email_verified"] == true
    sub = claims["sub"]
    raise Refused, "Sparklingstadt ID: the sub is not of its form" unless sub.is_a?(String) && sub.match?(SUB)
    name = claims["name"].to_s.strip.presence || claims["email"].to_s.split("@").first.to_s
    { sub:, name: }
  end
end

module OmniAuth
  module Strategies
    # The Sparklingstadt ID login: discovery from the issuer, the authorization code with PKCE (S256), state and nonce,
    # scope openid email profile, and the ID token verified (its signature by the ID server's JWKS, iss, aud, exp and
    # nonce). Its paths are /auth/sid and /auth/sid/callback.
    class Sid < OpenIDConnect
      option :name, "sid"
      option :discovery, true
      option :response_type, "code"
      option :scope, %i[openid email profile]
      option :pkce, true
      option :send_nonce, true

      # Off (the request goes on to the app, a 404) unless SID_ISSUER, SID_CLIENT_ID and SID_CLIENT_SECRET are set; they
      # are read on each request, as the sign-in page reads them.
      def call(env)
        SidLogin.enabled? ? super : @app.call(env)
      end

      def call!(env)
        options.issuer = ENV["SID_ISSUER"]
        options.client_options = options.client_options.merge(identifier: ENV["SID_CLIENT_ID"], secret: ENV["SID_CLIENT_SECRET"])
        super
      end

      # After a sign-out (the relogin cookie), the ID server asks for the password again.
      def authorize_uri
        options.prompt = request.cookies.key?(SidLogin::RELOGIN_COOKIE) ? :login : nil
        super
      end

      # A login that could not start (the ID server cannot be reached) is a failed login, not an error page.
      def request_phase
        super
      rescue ::OpenIDConnect::Exception, ::SWD::Exception, ::WebFinger::Exception, ::Faraday::Error, ::JSON::ParserError,
             ::SocketError, ::SystemCallError, ::Timeout::Error, ::OpenSSL::SSL::SSLError => e
        fail!(:failed_to_connect, e)
      end

      # So is an answer that cannot be read or trusted (a token that does not verify, a failed exchange).
      def callback_phase
        super
      rescue ::OpenIDConnect::Exception, ::JSON::JWT::Exception, ::SWD::Exception, ::WebFinger::Exception,
             ::Rack::OAuth2::Client::Error, ::Faraday::Error, ::JSON::ParserError, ::SocketError, ::SystemCallError,
             ::Timeout::Error, ::OpenSSL::SSL::SSLError => e
        fail!(:invalid_credentials, e)
      end

      private
        # The client settings of this request (call! made them its own), which discovery fills in, with the redirect URI
        # of this origin.
        def client_options
          options.client_options.tap { |settings| settings.redirect_uri ||= full_host + script_name + callback_path }
        end

        def decode_id_token(id_token)
          algorithm = ::JSON::JWT.decode(id_token, :skip_verification).algorithm.to_s.to_sym
          unless SidLogin::ID_TOKEN_ALGORITHMS.include?(algorithm)
            raise CallbackError, error: :invalid_jwt_algorithm, reason: "The ID token is signed with #{algorithm}"
          end
          super
        end

        # The nonce is only the one this browser's login was started with (not one the callback's query names).
        def verify_id_token!(id_token)
          return unless id_token
          decode_id_token(id_token).verify!(issuer: options.issuer, client_id: client_options.identifier, nonce: stored_nonce)
        end
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :sid
  provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"], scope: "read:user" if GithubLogin.enabled?
end
OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.on_failure = ->(env) { OmniauthCallbacksController.action(:failure).call(env) }
