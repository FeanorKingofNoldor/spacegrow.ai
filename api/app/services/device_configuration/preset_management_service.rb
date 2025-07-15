module DeviceConfiguration
  class PresetManagementService < ApplicationService
    def initialize(user)
      @user = user
    end

    def get_predefined_presets(device_type_id)
      Preset.where(
        device_type_id: device_type_id,
        user_id: nil,
        is_user_defined: false
      ).order(:name)
    end

    def get_user_presets(device_type_id)
      Preset.where(
        user_id: @user.id,
        device_type_id: device_type_id,
        is_user_defined: true
      ).order(created_at: :desc)
    end

    def create_preset(device, preset_params)
      preset = Preset.new(
        device_type: device.device_type,
        user: @user,
        is_user_defined: true,
        name: preset_params[:name],
        settings: build_settings(preset_params)
      )

      if preset.save
        OpenStruct.new(success?: true, preset: preset, message: 'Preset created successfully')
      else
        OpenStruct.new(success?: false, errors: preset.errors.full_messages)
      end
    end

    def update_preset(preset, preset_params)
      update_data = {
        name: preset_params[:name],
        settings: build_settings(preset_params)
      }.compact

      if preset.update(update_data)
        OpenStruct.new(success?: true, preset: preset, message: 'Preset updated successfully')
      else
        OpenStruct.new(success?: false, errors: preset.errors.full_messages)
      end
    end

    def delete_preset(preset)
      if preset.destroy
        OpenStruct.new(success?: true, message: 'Preset deleted successfully')
      else
        OpenStruct.new(success?: false, error: 'Failed to delete preset')
      end
    end

    def validate_preset_settings(device_type_id, settings)
      device_type = DeviceType.find(device_type_id)
      validation_service = DeviceConfiguration::PresetValidationService.new(settings, device_type)
      validation_service.call
    rescue ActiveRecord::RecordNotFound
      OpenStruct.new(
        valid?: false,
        errors: [{
          field: 'device_type_id',
          message: 'Device type not found',
          code: 'DEVICE_TYPE_NOT_FOUND'
        }],
        warnings: []
      )
    end

    private

    def build_settings(params)
      # If frontend sends settings as a nested object, use it directly
      if params[:settings].present?
        return params[:settings].to_h
      end
      
      # Otherwise, build from individual params (backward compatibility)
      settings = {}
      
      # Environmental Monitor settings
      settings[:lights] = params[:lights].reject { |_, v| v.blank? } if params[:lights].present?
      settings[:spray] = params[:spray].reject { |_, v| v.blank? } if params[:spray].present?
      
      # Liquid Monitor settings
      (1..5).each do |i|
        pump_key = "pump#{i}".to_sym
        if params[pump_key].present?
          settings[pump_key] = params[pump_key].reject { |_, v| v.blank? }
        end
      end
      
      settings.reject { |_, v| v.empty? }
    end
  end
end