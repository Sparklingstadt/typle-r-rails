# Who the request is for. A signed-in user works in their account; anyone else works in this browser's guest data,
# kept apart from every account (as typle-r keeps it in the browser's storage). Signing out goes back to it.
module Authentication
  extend ActiveSupport::Concern

  GUEST_COOKIE = :guest_id
  GUEST_LIMIT = 60
  GUEST_WINDOW = 10.minutes

  included do
    before_action :require_workspace
    helper_method :signed_in?, :current_user, :account, :return_to, :keep_return_to
  end

  class_methods do
    # Pages anyone may open without a workspace being made for them (the landing page, the catalog, sign-in).
    def allow_unauthenticated_access(**options)
      skip_before_action :require_workspace, **options
    end

    # Pages for an account only.
    def require_account(**options)
      before_action :require_signed_in, **options
    end
  end

  private
    def signed_in? = account.present?

    def account = resume_session&.user

    # The account, or this browser's guest when there is one; nil before a guest is needed.
    def current_user
      @current_user ||= account || find_guest
    end

    # A browser without a guest yet reads as an unsaved one (nothing of its own to show); the guest is saved when the
    # browser first writes something, so that opening pages (crawlers, scripts) adds no rows.
    def require_workspace
      @current_user = account || find_guest || (request.get? || request.head? ? User.new(guest: true) : create_guest)
    end

    def require_signed_in
      return if signed_in?
      redirect_to new_session_path(returnTo: request.fullpath)
    end

    # typle-r's returnPath: the page of this site that ?returnTo= names, to go back to after signing in; /home for
    # anything else (another site, a path with control characters or backslashes, nothing at all).
    def return_to(value = params[:returnTo])
      return "/home" unless value.is_a?(String) && value.start_with?("/") && !value.start_with?("//")
      return "/home" if value.match?(/[\u0000-\u001f\u007f\\]/)
      uri = URI.parse(value)
      uri.scheme || uri.host ? "/home" : value
    rescue URI::InvalidURIError
      "/home"
    end

    # typle-r's keep: the query that passes returnTo on to the next account page, left out when it is /home.
    def keep_return_to = return_to == "/home" ? {} : { returnTo: return_to }

    def find_guest
      id = cookies.signed[GUEST_COOKIE]
      id && User.find_by(id:, guest: true)
    end

    # New guests are counted by address (a classroom behind one address fits), so that one sender cannot fill the
    # database with them; past the limit the request is refused and nothing is made.
    def create_guest
      made = cache_store.increment("guests:#{request.remote_ip}", 1, expires_in: GUEST_WINDOW)
      if made && made > GUEST_LIMIT
        request.format.json? ? head(:too_many_requests) : redirect_to(root_path, alert: t("errors.rate_limited"))
        return
      end
      User.create_guest!.tap do |guest|
        cookies.signed.permanent[GUEST_COOKIE] = { value: guest.id, httponly: true, same_site: :lax }
      end
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def after_authentication_url = return_to

    def start_new_session_for(user)
      @current_user = nil
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      @current_user = nil
      cookies.delete(:session_id)
    end

    # After a sign-out that went through, the next Sparklingstadt ID login asks for the password again (prompt=login):
    # the ID server keeps its own login, which would otherwise let this browser straight back in.
    def remember_signed_out
      cookies[SidLogin::RELOGIN_COOKIE] = { value: "1", httponly: true, same_site: :lax, secure: request.ssl?,
                                            expires: SidLogin::RELOGIN_MAX_AGE.from_now }
    end
end
