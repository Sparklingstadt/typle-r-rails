# The device this browser practises on, for one user: kept in a cookie per browser and account, as typle-r keeps it in
# the browser. Nothing chosen yet is the built-in デフォルト; "" is 未選択 (no device recorded); a deleted device falls
# back to デフォルト.
class DeviceChoice
  NONE = ""

  def initialize(cookies, user)
    @cookies = cookies
    @user = user
  end

  def cookie_name = "device_#{@user.id}"

  def key
    value = @cookies[cookie_name]
    return NONE if value == NONE
    return Device::DEFAULT_KEY if value.nil? || value == Device::DEFAULT_KEY
    @user.devices.exists?(id: value) ? value : Device::DEFAULT_KEY
  end

  def key=(value)
    @cookies.permanent[cookie_name] = { value: value.to_s, same_site: :lax }
  end

  def none? = key == NONE
  def default? = key == Device::DEFAULT_KEY

  # What a record saved now keeps about the device; empty for 未選択.
  def snapshot
    return {} if none?
    default? ? Device.default_snapshot : @user.devices.find(key).snapshot
  end

  # The choices of a device menu: [label, key].
  def options
    [[I18n.t("devices.default_name"), Device::DEFAULT_KEY], *@user.devices.select(&:persisted?).map { |d| [d.name, d.key] }, [I18n.t("typle.devices.choice.none", default: I18n.t("devices.none")), NONE]]
  end
end
