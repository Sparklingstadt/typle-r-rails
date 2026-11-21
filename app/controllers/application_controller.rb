class ApplicationController < ActionController::Base
  include Authentication
  include Localization
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :typing_settings, :typing_options

  # A record of someone else, or one that is gone, is typle-r's 404 page (JSON requests get the status alone).
  rescue_from ActiveRecord::RecordNotFound do
    request.format.json? ? head(:not_found) : render("errors/not_found", status: :not_found, formats: :html)
  end

  private
    # The input settings, kept in this browser as typle-r keeps them (typle-r:simple-special-input, typle-r:ignore-case).
    def typing_settings = { ignore_accents: cookies[:ignore_accents] == "1", ignore_case: cookies[:ignore_case] == "1" }

    def typing_options = { ignoreAccents: typing_settings[:ignore_accents], ignoreCase: typing_settings[:ignore_case] }
end
