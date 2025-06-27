class Api::V1::Frontend::PresetsController < Api::V1::Frontend::ProtectedController
  before_action :set_device, only: [:create]

  def create
    authorize @device, :update?
    @preset = Preset.new
    @preset.device_type = @device.device_type
    @preset.user = current_user
    @preset.is_user_defined = true
    permitted_params = preset_params
    @preset.name = permitted_params[:name]
    @preset.settings = build_settings(permitted_params)

    if @preset.save
      render json: {
        status: 'success',
        data: @preset,
        message: 'Preset created successfully'
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: @preset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def show
    preset = Preset.find(params[:id])
    if preset.user_id == current_user.id || preset.user_id.nil?
      response = preset.as_json(only: [:id, :name, :settings]).merge(user_timezone: current_user.timezone)
      render json: {
        status: 'success',
        data: response
      }
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def user_by_device_type
    device_type_id = params[:device_type_id]
    presets = Preset.where(user_id: current_user.id, device_type_id: device_type_id)
                    .order(created_at: :desc)
    render json: {
      status: 'success',
      data: presets.as_json(only: [:id, :name])
    }
  end

  private

  def preset_params
    params.require(:preset).permit(
      :name,
      :device_id,
      lights: [:on_at, :off_at],
      spray: [:on_for, :off_for]
    )
  end

  def build_settings(params)
    {
      lights: params[:lights] || {},
      spray: params[:spray] || {}
    }.reject { |_, v| v.empty? }
  end

  def set_device
    @device = current_user.devices.find(params[:device_id] || params.dig(:preset, :device_id))
  end
end
