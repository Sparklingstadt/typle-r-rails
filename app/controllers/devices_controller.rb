# 端末: the devices a user practises on, how often each was used, and which one this browser practises on.
class DevicesController < ApplicationController
  def index
    @choice = DeviceChoice.new(cookies, current_user)
    @devices = current_user.devices.select(&:persisted?)
    records = current_user.practice_records.where.not(device_key: nil).group(:device_key)
    last = records.maximum(:practiced_at)
    @usage = records.count.to_h { |key, count| [key, { count:, last: last[key] }] }
    @device = current_user.devices.new
  end

  def create
    @device = current_user.devices.new(device_params)
    if @device.save
      choice = DeviceChoice.new(cookies, current_user)
      # Added while practising on デフォルト or nothing, the new device becomes the one to practise on.
      choice.key = @device.key if params[:use] == "1" && (choice.default? || choice.none?)
      redirect_to devices_path, notice: helpers.tt("devices.added", name: @device.name)
    else
      index_with_errors
    end
  end

  def update
    @device = current_user.devices.find(params[:id])
    if @device.update(device_params)
      redirect_to devices_path, notice: helpers.tt("devices.saved", name: @device.name)
    else
      index_with_errors
    end
  end

  def destroy
    device = current_user.devices.find(params[:id])
    device.destroy
    redirect_to devices_path, notice: helpers.tt("devices.deleted", name: device.name), status: :see_other
  end

  # Chooses the device this browser practises on (from 端末 or the practice screen).
  def choose
    choice = DeviceChoice.new(cookies, current_user)
    key = params[:key].to_s
    choice.key = key if key.in?(choice.options.map(&:last))
    redirect_back_or_to devices_path, status: :see_other
  end

  private
    def device_params = params.expect(device: %i[name layout])

    def index_with_errors
      failed = @device
      index
      @device = failed if failed.new_record?
      @editing = failed unless failed.new_record?
      render :index, status: :unprocessable_entity
    end
end
