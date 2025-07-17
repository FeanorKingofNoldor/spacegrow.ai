# app/controllers/api/v1/frontend/devices_controller.rb - REFACTORED
class Api::V1::Frontend::DevicesController < Api::V1::Frontend::ProtectedController
  include ApiResponseHandling
  include DeviceJsonHandling
  
  before_action :set_device, only: [:show, :update, :destroy, :update_status, :suspend, :wake]

  def index
    devices = current_user.devices.includes(:device_type)
    
    render_success(
      devices.map { |device| device_json(device) },
      devices.any? ? "Found #{devices.count} devices" : "No devices found"
    )
  end

  def show
    authorize @device
    render_success(detailed_device_json(@device))
  end

  def create
    result = DeviceManagement::OperationService.create_device(current_user, device_params)
    
    if result[:success]
      render_success(device_json(result[:device]), result[:message])
    else
      render_error(result[:error], result[:errors] || [])
    end
  end

  def update
    authorize @device
    
    if @device.update(device_params)
      render_success(device_json(@device), 'Device updated successfully')
    else
      render_error('Device update failed', @device.errors.full_messages)
    end
  end

  def destroy
    authorize @device
    
    @device.destroy
    render_success(nil, 'Device deleted successfully')
  end

  def update_status
    authorize @device
    
    if @device.update(status_params)
      render_success(device_json(@device), 'Device status updated successfully')
    else
      render_error('Status update failed', @device.errors.full_messages)
    end
  end

  def suspend
    authorize @device
    
    result = DeviceManagement::OperationService.suspend_device(@device, params[:reason])
    
    if result[:success]
      render_success({
        device: device_json(@device, include_suspension: true),
        **result[:suspension_data]
      }, result[:message])
    else
      render_error(result[:error], result[:errors] || [])
    end
  end

  def wake
    authorize @device
    
    result = DeviceManagement::OperationService.wake_device(@device)
    
    if result[:success]
      render_success({
        device: device_json(@device, include_suspension: true)
      }, result[:message])
    else
      if result[:limit_data]
        render_error(result[:error], [], 422)
      else
        render_error(result[:error], result[:errors] || [])
      end
    end
  end

  private

  def set_device
    @device = current_user.devices.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Device not found or access denied', [], 404)
  end

  def device_params
    params.require(:device).permit(
      :name, :device_type_id, :status, :order_id, :activation_token_id,
      :suspended_at, :suspended_reason, :grace_period_ends_at,
      :uuid, :api_key, :alert_status
    )
  end

  def status_params
    params.require(:device).permit(
      :status, :last_connection,
      :suspended_at, :suspended_reason, :grace_period_ends_at
    )
  end
end