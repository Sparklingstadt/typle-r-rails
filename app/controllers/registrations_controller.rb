class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: t("errors.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[login_id email password]))
    if @user.save(context: %i[create registration])
      AccountMailer.email_confirmation(@user).deliver_later if @user.email
      start_new_session_for @user
      # typle-r's sign-up says it is done, where the confirmation went, and the way on.
      render :done
    else
      render :new, status: :unprocessable_entity
    end
  end
end
