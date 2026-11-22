# A Sparklingstadt ID server for the tests, answered by WebMock: its discovery, keys (JWKS), token endpoint and
# userinfo, as the OpenID Connect login of config/initializers/omniauth.rb reads them.
module SidServerTestHelper
  ISSUER = ENV.fetch("SID_ISSUER")
  CLIENT_ID = ENV.fetch("SID_CLIENT_ID")
  KEY = OpenSSL::PKey::RSA.generate(2048)
  # A key the server never published: a token signed with it does not verify.
  OTHER_KEY = OpenSSL::PKey::RSA.generate(2048)

  def stub_sid_discovery
    stub_request(:get, "#{ISSUER}/.well-known/openid-configuration").to_return(sid_json(
      issuer: ISSUER, authorization_endpoint: "#{ISSUER}/authorize", token_endpoint: "#{ISSUER}/token",
      userinfo_endpoint: "#{ISSUER}/userinfo", jwks_uri: "#{ISSUER}/jwks", response_types_supported: %w[code],
      subject_types_supported: %w[public], id_token_signing_alg_values_supported: %w[RS256]))
    stub_request(:get, "#{ISSUER}/jwks").to_return(sid_json(keys: [JSON::JWK.new(KEY.public_key, kid: "k1")]))
  end

  # Starts a Sparklingstadt ID login (POST /auth/sid) and answers it as the ID server would for an ID of these claims,
  # then comes back to the callback. Answers the query the login was sent to the ID server with.
  # claims: the ID token's claims over the usual ones (nil leaves one out); key: the key it is signed with.
  def sign_in_with_sid(sub: "abc123", origin: nil, claims: {}, key: KEY, alg: :RS256)
    stub_sid_discovery
    post "/auth/sid", params: { origin: }.compact
    assert_response :redirect
    authorize = URI(response.location)
    assert_equal "#{ISSUER}/authorize", "#{authorize.scheme}://#{authorize.host}#{authorize.path}"
    query = Rack::Utils.parse_query(authorize.query)

    token_claims = { iss: ISSUER, sub:, aud: CLIENT_ID, exp: 1.hour.from_now.to_i, iat: Time.now.to_i, nonce: query["nonce"],
                     email: "#{sub}@example.com", email_verified: true, name: "Sid #{sub}" }.merge(claims).compact
    id_token = JSON::JWT.new(token_claims).tap { |jwt| jwt.kid = "k1" }.sign(key, alg).to_s
    stub_request(:post, "#{ISSUER}/token").to_return do |request|
      form = Rack::Utils.parse_query(request.body)
      # PKCE (S256): the verifier the login started with.
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(form["code_verifier"].to_s), padding: false)
      next { status: 400, body: { error: "invalid_grant" }.to_json, headers: { "Content-Type" => "application/json" } } if challenge != query["code_challenge"]
      sid_json(access_token: "access", token_type: "Bearer", expires_in: 3600, id_token:)
    end
    stub_request(:get, "#{ISSUER}/userinfo").to_return(sid_json(sub:))

    get "/auth/sid/callback", params: { code: "the-code", state: query["state"] }
    query
  end

  private
    def sid_json(body) = { status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" } }
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SidServerTestHelper
end
