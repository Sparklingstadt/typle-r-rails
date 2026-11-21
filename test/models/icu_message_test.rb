require "test_helper"

class IcuMessageTest < ActiveSupport::TestCase
  test "plurals, selects and ordinals as next-intl reads them" do
    russian = "Также будут удалены: {lists, plural, one {# список} few {# списка} many {# списков} other {# списка}} и {records, plural, one {# запись} few {# записи} many {# записей} other {# записи}}."
    assert_equal "Также будут удалены: 5 списков и 22 записи.", IcuMessage.format(russian, { lists: 5, records: 22 }, :ru)
    assert_equal "", IcuMessage.format("{n, plural, =0 {} other {# packs}}", { n: 0 }, :en)
    assert_equal "#2 3rd", IcuMessage.format("{name} {n, selectordinal, one {#st} two {#nd} few {#rd} other {#th}}", { name: "#2", n: 3 }, :en)
    assert_equal "slower", IcuMessage.format("{d, select, up {slower} other {faster}}", { d: "up" }, :en)
  end
end
