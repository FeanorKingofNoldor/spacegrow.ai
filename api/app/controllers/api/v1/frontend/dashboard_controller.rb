class Api::V1::Frontend::DashboardController < Api::V1::Frontend::ProtectedController
  def index
    @device_limit = current_user.pro? ? 4 : 2
    @devices = fetch_devices(@device_limit)
    @stats = Devices::AggregationService.new(@devices).call
    
    render json: {
      status: 'success',
      data: {
        device_limit: @device_limit,
        devices: @devices.map { |device| device_json(device) },
        stats: @stats
      }
    }
  end

  def devices
    authorize @device if @device
    @device_limit = current_user.pro? ? 4 : 2
    @devices = current_user.devices.includes(
      :device_type,
      device_sensors: [:sensor_type, :sensor_data]
    ).limit(@device_limit)
    
    @can_add_device = current_user.can_add_device?
    @stats = Devices::AggregationService.new(@devices).call
    
    @latest_readings = @devices.each_with_object({}) do |device, hash|
      device.device_sensors.each { |sensor| hash[sensor.id] = sensor.sensor_data.sort_by(&:timestamp).last }
    end

    render json: {
      status: 'success',
      data: {
        devices: @devices.map { |device| detailed_device_json(device) },
        can_add_device: @can_add_device,
        stats: @stats,
        latest_readings: @latest_readings
      }
    }
  end

  def device
    authorize @device if @device
    @device = current_user.devices.includes(
      :device_type,
      device_sensors: [:sensor_type, :sensor_data]
    ).find_by(id: params[:id])

    unless @device
      return render json: { error: "Device not found" }, status: :not_found
    end

    @sensor_groups = @device.device_sensors.group_by { |s| s.sensor_type.name }
    @latest_readings = @device.device_sensors.each_with_object({}) do |sensor, hash|
      hash[sensor.id] = sensor.sensor_data.sort_by(&:timestamp).last
    end
    @device_status = Devices::StatusService.new(@device).call
    @presets = @device.device_type&.presets&.predefined || []
    @profiles = @device.device_type&.presets&.profiles(current_user) || []

    render json: {
      status: 'success',
      data: {
        device: detailed_device_json(@device),
        sensor_groups: @sensor_groups,
        latest_readings: @latest_readings,
        device_status: @device_status,
        presets: @presets,
        profiles: @profiles
      }
    }
  end

  private

  def fetch_devices(limit)
    current_user.devices.includes(
      :device_type,
      device_sensors: [:sensor_type]
    ).limit(limit)
  end

  def device_json(device)
    authorize @device if @device
    {
      id: device.id,
      name: device.name,
      status: device.status,
      alert_status: device.alert_status,
      device_type: device.device_type&.name,
      last_connection: device.last_connection,
      created_at: device.created_at,
      updated_at: device.updated_at
    }
  end

  def detailed_device_json(device)
    device_json(device).merge({
      sensors: device.device_sensors.includes(:sensor_type).map do |sensor|
        {
          id: sensor.id,
          type: sensor.sensor_type.name,
          status: sensor.current_status,
          last_reading: sensor.sensor_data.order(:timestamp).last&.value
        }
      end
    })
  end
end
