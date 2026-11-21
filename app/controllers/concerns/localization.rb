# The display language, chosen on the settings screen and kept in a cookie for a year (typle-r's NEXT_LOCALE).
module Localization
  extend ActiveSupport::Concern

  LOCALES = %w[ja en zh-Hans zh-Hant ru fr].freeze
  NAMES = { "ja" => "日本語", "en" => "English", "zh-Hans" => "简体中文", "zh-Hant" => "繁體中文", "ru" => "Русский", "fr" => "Français" }.freeze
  COOKIE = :locale

  included do
    around_action :switch_locale
    helper_method :locale_names
  end

  private
    def switch_locale(&action)
      locale = LOCALES.include?(cookies[COOKIE]) ? cookies[COOKIE] : "ja"
      I18n.with_locale(locale, &action)
    end

    def locale_names = NAMES
end
