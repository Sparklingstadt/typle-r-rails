require "application_system_test_case"

# A deletion asks first (confirm_dialog.js): the dialog says what goes, cancelling keeps it, confirming deletes it.
class ConfirmDialogTest < ApplicationSystemTestCase
  test "deleting a device asks first" do
    visit devices_path(add: 1)
    fill_in "device-name", with: "Laptop"
    click_on I18n.t("design.settings.form.add")
    assert_selector "h3", text: "Laptop"
    device = Device.sole

    click_on I18n.t("design.settings.devices.deleteLabel", name: "Laptop")
    within("dialog[open]") do
      assert_text I18n.t("design.settings.devices.deleteTitle", name: "Laptop")
      find("[data-confirm-cancel]").click
    end
    assert_no_selector "dialog[open]"
    assert Device.exists?(device.id)

    click_on I18n.t("design.settings.devices.deleteLabel", name: "Laptop")
    within("dialog[open]") { find("[data-confirm-action]").click }
    assert_no_selector "h3", text: "Laptop"
    assert_not Device.exists?(device.id)
  end
end
