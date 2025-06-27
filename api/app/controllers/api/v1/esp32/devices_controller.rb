class Api::V1::Esp32::DevicesController < Api::V1::Esp32::BaseController
  skip_before_action :authenticate_device!, only: [:register, :validate]

  def register
    activation_token = DeviceActivationToken.find_by(token: params[:token])
    
    if activation_token && !activation_token.used?
      render json: {
        status: 'success',
        token: activation_token.token,
        commands: []
      }, status: :ok
    else
      render json: { error: 'Invalid activation token' }, status: :unauthorized
    end
  end

  def validate
    activation_token = DeviceActivationToken.find_by(token: params[:token])
    device_type = DeviceType.find_by(id: params[:device_type_id])
    
    if activation_token&.valid_for_activation?(device_type)
      result = DeviceActivationService.call(
        token: activation_token.token,
        device_type: device_type
      )
      
      if result.success?
        device = result.device
        device.update!(
          status: 'active',
          last_connection: Time.current
        )
        
        render json: {
          status: 'success',
          device_id: device.id,
          name: device.name,
          token: activation_token.token,
          commands: []
        }
      else
        render json: { error: result.error }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Invalid device credentials' }, status: :unauthorized
    end
  end

  def commands
    pending_commands = current_device.command_logs.pending
    render json: {
      commands: pending_commands.as_json(only: [:id, :command, :args]),
      utc_now: Time.now.utc.to_i
    }, status: :ok
  end

  def update_command_status
    command_log = current_device.command_logs.find_by(id: params[:command_id])
    if command_log && command_log.update(status: params[:status], message: params[:message])
      render json: { status: "success" }, status: :ok
    else
      render json: { error: "Failed to update command status" }, status: :unprocessable_entity
    end
  end
end
