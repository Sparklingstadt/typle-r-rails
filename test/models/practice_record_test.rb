require "test_helper"

class PracticeRecordTest < ActiveSupport::TestCase
  test "the default device is named in the language shown, whatever name was stored" do
    record = PracticeRecord.new(device_key: Device::DEFAULT_KEY, device_name: "デフォルト")
    I18n.with_locale(:en) { assert_equal "Default", record.device_label }
    assert_equal "Laptop", PracticeRecord.new(device_key: "abc", device_name: "Laptop").device_label
  end
end
