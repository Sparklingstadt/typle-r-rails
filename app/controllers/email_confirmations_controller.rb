class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    # As typle-r's /verify-email: the page says whether the address was confirmed, and leads home.
    user = User.find_by_token_for(:email_confirmation, params[:token])
    user&.update!(email_confirmed_at: Time.current)
    @confirmed = user.present?
    render status: (@confirmed ? :ok : :unprocessable_entity)
  end
end
