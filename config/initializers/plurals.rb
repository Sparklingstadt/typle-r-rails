# Plural rules (one/few/many/other) for the display languages; the rules themselves are in config/locales/plurals.rb,
# a locale file, so they are reloaded with the translations in development.
require "i18n/backend/pluralization"
I18n::Backend::Simple.include(I18n::Backend::Pluralization)
