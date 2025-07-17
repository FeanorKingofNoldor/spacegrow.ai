# app/controllers/api/v1/esp32/devices_controller.rb
class Api::V1::Esp32::DevicesController < Api::V1::Esp32::BaseController
  skip_before_action :authenticate_device!, only: [:register, :validate]

  def register
    result = DeviceCommunication::Esp32::DeviceRegistrationService.call(token: params[:token])
    
    if result[:success]
      render json: {
        status: 'success',
        token: result[:token],
        commands: result[:commands]
      }
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end

  def validate
    result = DeviceManagement::ActivationService.call(
      token: params[:token],
      device_type: DeviceType.find_by(id: params[:device_type_id])
    )
    
    if result[:success]
      device = result[:device]
      device.update!(last_connection: Time.current)
      
      render json: {
        status: 'success',
        device_id: device.id,
        name: device.name,
        token: params[:token],
        commands: [],
        device_status: {
          status: device.status,
          operational: device.operational?,
          suspended: device.suspended?,
          in_grace_period: device.in_grace_period?
        }
      }
    else
      render json: { 
        error: 'Device activation failed',
        details: result[:error] 
      }, status: :unprocessable_entity
    end
  end

  def status
    status_result = DeviceManagement::StatusService.call(@device)
    
    render json: {
      status: 'success',
      device_status: {
        id: @device.id,
        name: @device.name,
        status: status_result[:operational_status],
        alert_status: status_result[:alert_status],
        last_connection: @device.last_connection,
        can_send_data: @device.active?
      }
    }
  end

  def commands
    result = DeviceCommunication::Esp32::CommandRetrievalService.call(@device)
    
    if result[:success]
      render json: {
        status: 'success',
        commands: result[:commands]
      }
    else
      render json: { error: result[:error] }, status: :forbidden
    end
  end

  def update_command_status
    command_log = @device.command_logs.find(params[:command_id])
    
    if command_log.update(status: params[:status])
      render json: { status: 'success' }
    else
      render json: { error: 'Invalid status' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Command not found' }, status: :not_found
  end
end