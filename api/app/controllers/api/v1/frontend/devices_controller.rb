class Api::V1::Frontend::DevicesController < Api::V1::Frontend::ProtectedController
  before_action :set_device, only: [:show, :update, :destroy, :update_status]

  def index
    devices = current_user.devices.includes(:device_type)
    
    render json: {
      status: 'success',
      data: devices.map { |device| device_json(device) },
      message: devices.any? ? "Found #{devices.count} devices" : "No devices found"
    }
  end

  def show
    authorize @device
    render json: {
      status: 'success',
      data: detailed_device_json(@device)
    }
  end

  def create
    device = current_user.devices.build(device_params)
    
    if device.save
      render json: {
        status: 'success',
        message: 'Device created successfully',
        data: device_json(device)
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: device.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    authorize @device
    if @device.update(device_params)
      render json: {
        status: 'success',
        message: 'Device updated successfully',
        data: device_json(@device)
      }
    else
      render json: {
        status: 'error',
        errors: @device.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @device
    @device.destroy
    render json: {
      status: 'success',
      message: 'Device deleted successfully'
    }
  end

  def update_status
    authorize @device
    authorize @device
    if @device.update(status_params)
      render json: {
        status: 'success',
        message: 'Device status updated successfully',
        data: device_json(@device)
      }
    else
      render json: {
        status: 'error',
        errors: @device.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_device
    @device = current_user.devices.find(params[:id])
  end

  def device_params
    params.require(:device).permit(:name, :device_type_id, :status)
  end

  def status_params
    params.require(:device).permit(:status)
  end

  def device_json(device)
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
