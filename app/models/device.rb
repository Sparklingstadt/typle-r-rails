# A keyboard or computer a user practises on (端末). Every user also has the built-in デフォルト device, which is not
# stored (DEFAULT_KEY): it cannot be renamed or deleted and does not count toward MAX.
class Device < ApplicationRecord
  DEFAULT_KEY = "default"
  MAX = 100

  belongs_to :user

  normalizes :name, :layout, with: ->(value) { value.to_s.strip }

  validates :name, presence: true, length: { maximum: 100 }
  validates :layout, length: { maximum: 200 }
  validate :name_is_unique, :within_limit

  def key = id.to_s

  # What a record keeps: the device as it was when the run was practised.
  def snapshot = { device_key: key, device_name: name, device_layout: layout }

  def self.default_snapshot = { device_key: DEFAULT_KEY, device_name: I18n.t("devices.default_name"), device_layout: "" }

  private
    def name_is_unique
      same = user.devices.where.not(id:).find { |device| device.name.casecmp?(name) }
      errors.add(:name, :taken_device, name: same.name) if same
      errors.add(:name, :taken_device, name:) if name.casecmp?(I18n.t("devices.default_name"))
    end

    def within_limit
      errors.add(:base, :device_limit, count: MAX) if new_record? && user.devices.count >= MAX
    end
end
