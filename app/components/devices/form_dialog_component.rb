# typle-r's DeviceDialog: the form adding a device, or editing one, in a dialog over 端末 (modal_controller.js opens it;
# closing goes back to the page). Editing a device with `records` runs says the runs keep their old name.
class Devices::FormDialogComponent < ApplicationComponent
  delegate :settings_t, :tt, :label_classes, :input_classes, :alert_classes, to: :helpers

  # Each field: attribute, id, the label's, placeholder's and help's keys, the maximum length and whether it is required.
  FIELDS = [
    [:name, "device-name", "devices.dialog.name", "devices.dialog.namePlaceholder", "devices.dialog.nameHelp", 100, true],
    [:layout, "device-layout", "devices.dialog.layout", "devices.dialog.layoutPlaceholder", "devices.dialog.layoutHelp", 200, false]
  ].freeze

  def initialize(device:, editing:, records:, choice:)
    @device = device
    @editing = editing
    @records = records
    @choice = choice
  end

  private

  attr_reader :records

  def record = @device

  def editing = @editing

  def form_url = editing ? device_path(@device) : devices_path

  # A new device becomes the one to practise on when this browser practises on デフォルト or nothing.
  def use_by_default? = @choice.default? || @choice.none?

  # The field's error in typle-r's words.
  def field_error(attribute)
    error = record.errors.where(attribute).first or return
    case [attribute, error.type]
    in [:name, :blank] then tt("errors.deviceNameRequired")
    in [:name, :too_long] then tt("errors.deviceNameTooLong", max: 100)
    in [:name, :taken_device] then tt("errors.deviceNameDuplicate", name: error.options[:name])
    in [:layout, _] then tt("errors.deviceLayoutTooLong", max: 200)
    else error.full_message
    end
  end

  def form_error = record.errors.where(:base).first&.message
end
