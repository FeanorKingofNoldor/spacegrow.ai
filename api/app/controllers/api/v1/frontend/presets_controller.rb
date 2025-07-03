# app/controllers/api/v1/frontend/presets_controller.rb
class Api::V1::Frontend::PresetsController < Api::V1::Frontend::ProtectedController
  before_action :set_device, only: [:create]
  before_action :set_preset, only: [:show, :update, :destroy]
  before_action :validate_preset_ownership, only: [:update, :destroy]

  # ✅ NEW: Get predefined presets by device type (this was missing!)
  def by_device_type
    device_type_id = params[:device_type_id]
    
    # Get predefined presets for this device type
    presets = Preset.where(
      device_type_id: device_type_id,
      user_id: nil,              # Predefined presets have no user_id
      is_user_defined: false     # Explicitly not user-defined
    ).order(:name)
    
    render json: {
      status: 'success',
      data: presets.as_json(
        only: [:id, :name, :settings, :device_type_id, :is_user_defined, :created_at]
      )
    }
  end

  # ✅ EXISTING: Get user's custom presets by device type
  def user_by_device_type
    device_type_id = params[:device_type_id]
    presets = Preset.where(
      user_id: current_user.id, 
      device_type_id: device_type_id,
      is_user_defined: true
    ).order(created_at: :desc)
    
    render json: {
      status: 'success',
      data: presets.as_json(
        only: [:id, :name, :settings, :device_type_id, :is_user_defined, :created_at]
      )
    }
  end

  # ✅ EXISTING: Create new user preset
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
        data: @preset.as_json(
          only: [:id, :name, :settings, :device_type_id, :is_user_defined, :created_at]
        ),
        message: 'Preset created successfully'
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: @preset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # ✅ EXISTING: Show single preset
  def show
    if @preset.user_id == current_user.id || @preset.user_id.nil?
      response = @preset.as_json(only: [:id, :name, :settings]).merge(
        user_timezone: current_user.timezone,
        device_type: @preset.device_type.as_json(only: [:id, :name, :configuration])
      )
      render json: {
        status: 'success',
        data: response
      }
    else
      render json: { 
        status: 'error', 
        error: "Unauthorized" 
      }, status: :unauthorized
    end
  end

  # ✅ NEW: Update user preset
  def update
    permitted_params = preset_params
    update_data = {
      name: permitted_params[:name],
      settings: build_settings(permitted_params)
    }.compact

    if @preset.update(update_data)
      render json: {
        status: 'success',
        data: @preset.as_json(
          only: [:id, :name, :settings, :device_type_id, :is_user_defined, :updated_at]
        ),
        message: 'Preset updated successfully'
      }
    else
      render json: {
        status: 'error',
        errors: @preset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # ✅ NEW: Delete user preset
  def destroy
    if @preset.destroy
      render json: {
        status: 'success',
        message: 'Preset deleted successfully'
      }
    else
      render json: {
        status: 'error',
        error: 'Failed to delete preset'
      }, status: :unprocessable_entity
    end
  end

  # ✅ NEW: Validate preset settings
  def validate
    device_type_id = params[:device_type_id]
    settings = params[:settings]
    
    begin
      # Find device type
      device_type = DeviceType.find(device_type_id)
      
      # Perform validation based on device type
      validation_result = validate_settings_for_device_type(settings, device_type)
      
      render json: {
        status: 'success',
        data: validation_result
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: 'error',
        data: {
          valid: false,
          errors: [{
            field: 'device_type_id',
            message: 'Device type not found',
            code: 'DEVICE_TYPE_NOT_FOUND'
          }]
        }
      }
    rescue => e
      render json: {
        status: 'error',
        data: {
          valid: false,
          errors: [{
            field: 'general',
            message: e.message,
            code: 'VALIDATION_ERROR'
          }]
        }
      }
    end
  end

  private

  # ✅ FIXED: Handle both formats - direct settings or nested params
  def preset_params
    params.require(:preset).permit(
      :name,
      :device_id,
      # Allow nested settings object (from frontend)
      settings: {},
      # Also allow individual fields (for backward compatibility)
      lights: [:on_at, :off_at],
      spray: [:on_for, :off_for],
      pump1: [:duration],
      pump2: [:duration],
      pump3: [:duration],
      pump4: [:duration],
      pump5: [:duration]
    )
  end

  # ✅ FIXED: Build settings from either format
  def build_settings(params)
    # If frontend sends settings as a nested object, use it directly
    if params[:settings].present?
      return params[:settings].to_h
    end
    
    # Otherwise, build from individual params (old format)
    settings = {}
    
    # Environmental Monitor settings
    if params[:lights].present?
      settings[:lights] = params[:lights].reject { |_, v| v.blank? }
    end
    
    if params[:spray].present?
      settings[:spray] = params[:spray].reject { |_, v| v.blank? }
    end
    
    # Liquid Monitor settings
    (1..5).each do |i|
      pump_key = "pump#{i}".to_sym
      if params[pump_key].present?
        settings[pump_key] = params[pump_key].reject { |_, v| v.blank? }
      end
    end
    
    settings.reject { |_, v| v.empty? }
  end

  def set_device
    @device = current_user.devices.find(params[:device_id] || params.dig(:preset, :device_id))
  end

  def set_preset
    @preset = Preset.find(params[:id])
  end

  def validate_preset_ownership
    unless @preset.editable_by?(current_user)
      render json: { 
        status: 'error', 
        error: 'You can only modify your own presets' 
      }, status: :forbidden
    end
  end

  # ✅ NEW: Settings validation logic
  def validate_settings_for_device_type(settings, device_type)
    errors = []
    warnings = []
    
    case device_type.name
    when 'Environmental Monitor V1'
      errors.concat(validate_environmental_settings(settings))
    when 'Liquid Monitor V1'
      errors.concat(validate_liquid_monitor_settings(settings))
    else
      warnings << "Unknown device type: #{device_type.name}"
    end
    
    {
      valid: errors.empty?,
      errors: errors,
      warnings: warnings
    }
  end

  def validate_environmental_settings(settings)
    errors = []
    
    # Validate lights
    if settings['lights'].present?
      lights = settings['lights']
      if lights['on_at'].present? && lights['off_at'].present?
        begin
          on_time = Time.parse(lights['on_at'].gsub('hrs', ''))
          off_time = Time.parse(lights['off_at'].gsub('hrs', ''))
          
          if on_time >= off_time
            errors << {
              field: 'lights',
              message: 'Lights on time must be before lights off time',
              code: 'INVALID_TIME_RANGE'
            }
          end
        rescue ArgumentError
          errors << {
            field: 'lights',
            message: 'Invalid time format. Use HH:MMhrs format',
            code: 'INVALID_TIME_FORMAT'
          }
        end
      end
    end
    
    # Validate spray
    if settings['spray'].present?
      spray = settings['spray']
      if spray['on_for'].present? && spray['on_for'].to_i <= 0
        errors << {
          field: 'spray.on_for',
          message: 'Spray on duration must be greater than 0',
          code: 'INVALID_DURATION'
        }
      end
      
      if spray['off_for'].present? && spray['off_for'].to_i <= 0
        errors << {
          field: 'spray.off_for',
          message: 'Spray off duration must be greater than 0',
          code: 'INVALID_DURATION'
        }
      end
    end
    
    errors
  end

  def validate_liquid_monitor_settings(settings)
    errors = []
    active_pumps = 0
    
    (1..5).each do |i|
      pump_key = "pump#{i}"
      if settings[pump_key].present?
        duration = settings[pump_key]['duration'].to_i
        if duration > 0
          active_pumps += 1
          if duration > 300 # 5 minutes max
            errors << {
              field: "#{pump_key}.duration",
              message: "Pump #{i} duration cannot exceed 300 seconds",
              code: 'DURATION_TOO_LONG'
            }
          end
        end
      end
    end
    
    if active_pumps == 0
      errors << {
        field: 'pumps',
        message: 'At least one pump must have a duration greater than 0',
        code: 'NO_ACTIVE_PUMPS'
      }
    end
    
    errors
  end
end