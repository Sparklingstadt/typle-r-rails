require "test_helper"

# Every page in every display language: a missing translation raises in tests.
class LocalesTest < ActionDispatch::IntegrationTest
  PAGES = %w[/ /about /guide /home /play /records /rankings /rankings?mode=writing /packs /words /catalog
             /catalog/pack-vim-beginner /settings /input /interests /devices /packs/new
             /forgot-password /forgot-id /signin /signup].freeze

  Localization::LOCALES.each do |locale|
    test "every page renders in #{locale}" do
      user = users(:one)
      list = OfficialCatalog.follow(user, "pack-korean-handwriting-beginner-words-1").word_lists.first
      record = list.practice_records.create!(user:, time_ms: 1500, accuracy: 90, mistakes: 1, word_count: list.words.size,
        missed: [{ "word" => list.words.first.input, "count" => 1 }], device_key: "default", device_name: "x")
      # An own pack with a list and a record, so its delete dialogs (with their plurals) are on the page too.
      own = user.packs.create!(name: "Own", category: "Shell", tags: %w[Linux])
      own_list = own.word_lists.new(user:, name: "Own list", words_text: "ls")
      own_list.save!
      own_list.practice_records.create!(user:, time_ms: 900, accuracy: 100, mistakes: 0, word_count: 1, device_key: "default", device_name: "x")
      sign_in_as user
      patch locale_settings_path, params: { locale: }

      (PAGES + ["/play?list=#{list.id}&mode=writing", "/play?list=#{list.id}&mode=recall", "/records/#{record.id}",
                "/packs?pack=#{list.pack_id}", "/packs?pack=#{own.id}", "/packs/#{own.id}/edit", "/word_lists/#{own_list.id}/edit", "/play?list=#{list.id}&review=weak"]).each do |path|
        get path
        assert_response :success, "#{locale} #{path}"
        assert_select "html[lang=?]", locale
      end
      I18n.with_locale(locale) do
        user.update!(email: "one@example.com")
        AccountMailer.password_reset(user).deliver_now
        AccountMailer.login_id_reminder(user).deliver_now
        AccountMailer.email_confirmation(user).deliver_now
      end
    end
  end
end
