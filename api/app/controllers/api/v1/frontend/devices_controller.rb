# app/controllers/api/v1/frontend/devices_controller.rb
class Api::V1::Frontend::DevicesController < Api::V1::Frontend::ProtectedController
  before_action :set_device, only: [:show, :update, :destroy, :update_status, :hibernate, :wake]

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
    # ✅ FIXED: Check against ACTIVE device limit (not total devices)
    current_active_devices = current_user.devices.where(status: 'active').count
    device_limit = current_user.device_limit

    if current_active_devices >= device_limit
      return render json: {
        status: 'error',
        errors: ["Active device limit of #{device_limit} reached for your current plan"]
      }, status: :unprocessable_entity
    end

    # ✅ FIXED: Create device as 'pending' - it will be activated via ESP32 flow
    device_params_with_defaults = device_params.merge(status: 'pending')
    device = current_user.devices.build(device_params_with_defaults)
    
    if device.save
      # ✅ IMPORTANT: Generate activation token for the device
      if device.order.present?
        DeviceActivationTokenService.generate_for_order(device.order)
      end

      render json: {
        status: 'success',
        message: 'Device created successfully. Use the activation token to register your device.',
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

  # ✅ NEW: Hibernate device endpoint
  def hibernate
    authorize @device
    reason = params[:reason] || 'User requested hibernation'
    
    if @device.hibernating?
      return render json: {
        status: 'error',
        message: 'Device is already hibernated'
      }, status: :unprocessable_entity
    end
    
    if @device.hibernate!(reason: reason)
      render json: {
        status: 'success',
        message: 'Device hibernated successfully',
        data: {
          device: device_json(@device, include_hibernation: true),
          hibernated_at: @device.hibernated_at,
          hibernated_reason: @device.hibernated_reason,
          grace_period_ends_at: @device.grace_period_ends_at
        }
      }
    else
      render json: {
        status: 'error',
        errors: @device.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # ✅ NEW: Wake device endpoint
  def wake
    authorize @device
    
    if !@device.hibernating?
      return render json: {
        status: 'error',
        message: 'Device is not hibernated'
      }, status: :unprocessable_entity
    end

    # Check if user has available device slots
    subscription = current_user.subscription
    if subscription && subscription.operational_devices_count >= subscription.device_limit
      return render json: {
        status: 'error',
        message: 'Cannot wake device: subscription device limit reached',
        data: {
          current_operational: subscription.operational_devices_count,
          device_limit: subscription.device_limit,
          upsell_options: subscription.generate_upsell_options
        }
      }, status: :unprocessable_entity
    end
    
    if @device.wake_up!
      render json: {
        status: 'success',
        message: 'Device woken up successfully',
        data: {
          device: device_json(@device, include_hibernation: true)
        }
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
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      error: 'Device not found or access denied'
    }, status: :not_found
  end

def device_params
  params.require(:device).permit(
    :name, :device_type_id, :status, :order_id, :activation_token_id,
    :hibernated_at, :hibernated_reason, :grace_period_ends_at
  )
end

def status_params
  params.require(:device).permit(
    :status, :last_connection,
    :hibernated_at, :hibernated_reason, :grace_period_ends_at
  )
end

  def device_json(device, include_hibernation: false)
    json = {
      id: device.id,
      name: device.name,
      status: device.status,
      alert_status: device.alert_status,
      device_type: device.device_type&.name,
      last_connection: device.last_connection,
      created_at: device.created_at,
      updated_at: device.updated_at,
      # ✅ ADDED: Include activation status for frontend
      is_activated: device.status == 'active',
      needs_activation: device.status == 'pending',
      operational: device.operational?
    }
    
    if include_hibernation
      json.merge!({
        hibernating: device.hibernating?,
        hibernated_at: device.hibernated_at,
        hibernated_reason: device.hibernated_reason,
        in_grace_period: device.in_grace_period?,
        grace_period_ends_at: device.grace_period_ends_at
      })
    end
    
    json
  end

  def detailed_device_json(device)
    {
      device: device_json(device, include_hibernation: true),
      sensor_groups: group_sensors_by_type(device),
      latest_readings: get_latest_readings(device),
      device_status: calculate_device_status(device),
      presets: [],
      profiles: []
    }
  end

  def group_sensors_by_type(device)
    device.device_sensors.includes(:sensor_type).group_by { |sensor| sensor.sensor_type.name }.transform_values do |sensors|
      sensors.map do |sensor|
        {
          id: sensor.id,
          type: sensor.sensor_type.name,
          status: sensor.current_status,
          last_reading: sensor.sensor_data.order(:timestamp).last&.value,
          sensor_type: {
            id: sensor.sensor_type.id,
            name: sensor.sensor_type.name,
            unit: sensor.sensor_type.unit,
            min_value: sensor.sensor_type.min_value,
            max_value: sensor.sensor_type.max_value
          }
        }
      end
    end
  end

  def get_latest_readings(device)
    device.device_sensors.includes(:sensor_data).each_with_object({}) do |sensor, hash|
      latest = sensor.sensor_data.order(:timestamp).last
      hash[sensor.id] = latest&.value
    end
  end

  def calculate_device_status(device)
    {
      overall_status: device.status,
      alert_level: device.alert_status,
      last_seen: device.last_connection,
      connection_status: device.last_connection && 
        Time.parse(device.last_connection.to_s) > 10.minutes.ago ? 'online' : 'offline'
    }
  end
end