class SettingsController < ApplicationController
  allow_unauthenticated_access

  # 入力
  def show
  end

  def update
    params.expect(user: %i[ignore_accents ignore_case]).each do |name, value|
      cookies.permanent[name] = { value: value == "1" ? "1" : "0", same_site: :lax }
    end
    redirect_to input_settings_path, notice: t(".saved")
  end

  # 一般: the display language.
  def general
  end

  def locale
    locale = params[:locale].to_s
    cookies.permanent[Localization::COOKIE] = { value: locale, same_site: :lax } if Localization::LOCALES.include?(locale)
    redirect_to general_settings_path, status: :see_other
  end
end
