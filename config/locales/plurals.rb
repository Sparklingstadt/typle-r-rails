# Plural rules for the display languages (Rails knows only one/other). Russian has one/few/many; French counts 0 and 1
# as one; Chinese and Japanese do not change with the number.
russian = lambda do |n|
  mod10 = n % 10
  mod100 = n % 100
  if mod10 == 1 && mod100 != 11 then :one
  elsif (2..4).cover?(mod10) && !(12..14).cover?(mod100) then :few
  else :many
  end
end
english = ->(n) { n == 1 ? :one : :other }
none = ->(_n) { :other }

{
  ja: { i18n: { plural: { rule: none } } },
  "zh-Hans": { i18n: { plural: { rule: none } } },
  "zh-Hant": { i18n: { plural: { rule: none } } },
  en: { i18n: { plural: { rule: english } } },
  ru: { i18n: { plural: { rule: russian } } },
  fr: { i18n: { plural: { rule: ->(n) { n < 2 ? :one : :other } } } }
}
