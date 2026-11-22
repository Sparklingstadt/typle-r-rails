# Be sure to restart your server when you modify this file.

# The content security policy: what a page may load and run, so that markup that slips into a page cannot run script.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    # Scripts are the app's own files and the inline ones that carry the nonce; the handwriting pad compiles
    # WebAssembly (public/handwriting/ort).
    policy.script_src  :self, :wasm_unsafe_eval
    # Charts and the 404 page place things with style attributes; the font's stylesheet is Google Fonts'.
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :blob
    policy.connect_src :self
    policy.object_src  :none
    policy.base_uri    :self
    # Forms post to the app; the sign-in forms go on to the Sparklingstadt ID server (SID_ISSUER) and github.com.
    sid_origin = (URI.parse(ENV["SID_ISSUER"].to_s).then { |uri| "#{uri.scheme}://#{uri.authority}" if uri.scheme && uri.host } rescue nil)
    policy.form_action :self, *sid_origin, "https://github.com"
    policy.frame_ancestors :self
  end

  # The nonce of inline scripts and the importmap. It is kept in the session, so the pages Turbo swaps in share it
  # (the session's id is not used: a first visit has none yet, and its scripts would be refused).
  config.content_security_policy_nonce_generator = ->(request) { request.session[:csp_nonce] ||= SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
