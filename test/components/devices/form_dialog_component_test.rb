require "test_helper"

class Devices::FormDialogComponentTest < ViewComponent::TestCase
  setup do
    @user = users(:one)
    @choice = DeviceChoice.new(ActionDispatch::Request.empty.cookie_jar, @user)
  end

  test "adding a device: an empty form that becomes the one to practise on" do
    render_inline(Devices::FormDialogComponent.new(device: Device.new(user: @user), editing: false, records: 0, choice: @choice))

    assert_selector "dialog form[action='/devices'][method=post]"
    assert_selector "input#device-name[aria-required=true]"
    assert_selector "input#device-use[checked]", visible: :all
  end

  test "editing a device used for runs says the runs keep their name" do
    device = @user.devices.create!(name: "Laptop")
    render_inline(Devices::FormDialogComponent.new(device:, editing: true, records: 3, choice: @choice))

    assert_selector "form[action='/devices/#{device.id}'] input[name=_method][value=patch]", visible: :all
    assert_selector "input#device-name[value=Laptop]"
    assert_selector "svg.lucide-info"
    assert_no_selector "#device-use", visible: :all
  end

  test "errors are in typle-r's words, tied to their field" do
    @user.devices.create!(name: "Laptop")
    device = @user.devices.new(name: "", layout: "x" * 201)
    device.validate
    render_inline(Devices::FormDialogComponent.new(device:, editing: false, records: 0, choice: @choice))

    assert_selector "input#device-name[aria-invalid=true][aria-describedby='device-name-error device-name-help']"
    assert_selector "p#device-name-error", text: I18n.t("typle.errors.deviceNameRequired")
    assert_selector "p#device-layout-error", text: I18n.t("typle.errors.deviceLayoutTooLong", max: 200)
  end
end
