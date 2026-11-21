# The device filter's choices (typle-r's deviceOptions): taken from the records themselves, so deleted or renamed devices
# can still be picked, by key, with the newest name. Records without a device are grouped last, as ListRanking::NO_DEVICE.
class DeviceOptions
  include Enumerable

  # `latest` is the newest record made on the device: its name and layout are what the choice shows.
  Option = Data.define(:value, :latest, :count, :deleted)

  def initialize(user, records)
    keys = user.devices.map(&:key) << Device::DEFAULT_KEY
    groups = records.sort_by { |record| -record.practiced_at.to_f }.group_by { |record| record.device_key || ListRanking::NO_DEVICE }
    @options = groups.map { |value, items|
      Option.new(value:, latest: items.first, count: items.size, deleted: value != ListRanking::NO_DEVICE && !keys.include?(value))
    }.sort_by { |option| [option.value == ListRanking::NO_DEVICE ? 1 : 0, -option.count] }
  end

  def each(&) = @options.each(&)
  def option_for(value) = value.presence && @options.find { |option| option.value == value }
end
