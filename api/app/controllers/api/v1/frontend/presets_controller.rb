# app/controllers/api/v1/frontend/presets_controller.rb - REFACTORED
class Api::V1::Frontend::PresetsController < Api::V1::Frontend::ProtectedController
  include ApiResponseHandling
  include PresetJsonHandling
  
  before_action :set_device, only: [:create]
  before_action :set_preset, only: [:show, :update, :destroy]
  before_action :validate_preset_ownership, only: [:update, :destroy]

  def by_device_type
    presets = DeviceConfiguration::DeviceConfiguration::DeviceConfiguration::PresetManagementService.new(current_user).get_predefined_presets(params[:device_type_id])
    render_success(presets_collection_json(presets))
  end

  def user_by_device_type
    presets = DeviceConfiguration::DeviceConfiguration::DeviceConfiguration::PresetManagementService.new(current_user).get_user_presets(params[:device_type_id])
    render_success(presets_collection_json(presets))
  end

  def create
    authorize @device, :update?
    
    result = DeviceConfiguration::DeviceConfiguration::DeviceConfiguration::PresetManagementService.new(current_user).create_preset(@device, preset_params)
    
    if result.success?
      render_success(preset_json(result.preset), result.message)
    else
      render_error('Preset creation failed', result.errors)
    end
  end

  def show
    if @preset.user_id == current_user.id || @preset.user_id.nil?
      render_success(preset_json(@preset, include_details: true))
    else
      render_error('Unauthorized', [], 403)
    end
  end

  def update
    result = DeviceConfiguration::DeviceConfiguration::DeviceConfiguration::PresetManagementService.new(current_user).update_preset(@preset, preset_params)
    
    if result.success?
      render_success(preset_json(result.preset), result.message)
    else
      render_error('Preset update failed', result.errors)
    end
  end

  def destroy
    result = DeviceConfiguration::DeviceConfiguration::DeviceConfiguration::PresetManagementService.new(current_user).delete_preset(@preset)
    
    if result.success?
      render_success(nil, result.message)
    else
      render_error(result.error)
    end
  end

  def validate
    result = DeviceConfiguration::DeviceConfiguration::DeviceConfiguration::PresetManagementService.new(current_user).validate_preset_settings(
      params[:device_type_id],
      params[:settings]
    )
    
    render_success({
      valid: result.valid?,
      errors: result.errors,
      warnings: result.warnings
    })
  rescue => e
    render_error('Validation failed', [{ field: 'general', message: e.message, code: 'VALIDATION_ERROR' }])
  end

  private

  def set_device
    @device = current_user.devices.find(params[:device_id] || params.dig(:preset, :device_id))
  rescue ActiveRecord::RecordNotFound
    render_error('Device not found', [], 404)
  end

  def set_preset
    @preset = Preset.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Preset not found', [], 404)
  end

  def validate_preset_ownership
    unless @preset.editable_by?(current_user)
      render_error('You can only modify your own presets', [], 403)
    end
  end

  def preset_params
    params.require(:preset).permit(
      :name, :device_id,
      settings: {},
      lights: [:on_at, :off_at],
      spray: [:on_for, :off_for],
      pump1: [:duration], pump2: [:duration], pump3: [:duration], pump4: [:duration], pump5: [:duration]
    )
  end
end