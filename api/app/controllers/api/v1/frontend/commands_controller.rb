class Api::V1::Frontend::CommandsController < Api::V1::Frontend::ProtectedController
  before_action :set_device

  def create
    authorize @device, :update?
    command = params[:command]
    args = params[:args] || {}
    
    result = DeviceCommunication::CommandService.new(@device).execute(command, args)
    
    if result[:success]
      render json: {
        status: 'success',
        message: 'Command queued successfully'
      }, status: :ok
    else
      render json: {
        status: 'error',
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  private

  def set_device
    @device = current_user.devices.find(params[:device_id])
  end
end