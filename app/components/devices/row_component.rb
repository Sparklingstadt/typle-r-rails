# A device on 端末 (`device` nil is デフォルト): its name, layout and use, whether this browser practises on it, and for a
# device of the user's, buttons to edit and delete it.
class Devices::RowComponent < ApplicationComponent
  delegate :settings_t, :records_day, :delete_confirm_data, :ui_badge, :icon_tile, to: :helpers

  def initialize(device:, usage:, current_key:)
    @device = device
    @usage = usage
    @current_key = current_key
  end

  private

  attr_reader :device, :usage

  def key = device ? device.key : Device::DEFAULT_KEY

  def name = device ? device.name : t("devices.default_name")

  def current? = key == @current_key

  # Deleting says what goes: the device, whether its runs keep their name, and that this browser stops practising on it.
  def delete_confirm
    delete_confirm_data(title: settings_t("devices.deleteTitle", name:),
      description: [settings_t("devices.deleteRemoval", name:),
                    usage ? settings_t("devices.deleteRecords", count: usage[:count]) : settings_t("devices.deleteNoRecords"),
                    (settings_t("devices.deleteCurrent") if current?)].compact.join)
  end
end
