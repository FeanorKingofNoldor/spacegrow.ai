# app/services/device_configuration/preset_management_service.rb - REFACTORED
module DeviceConfiguration
  class PresetManagementService < ApplicationService
    def initialize(user)
      @user = user
    end

    def get_predefined_presets(device_type_id)
      begin
        presets = Preset.where(
          device_type_id: device_type_id,
          user_id: nil,
          is_user_defined: false
        ).order(:name)

        success(
          presets: presets,
          count: presets.count,
          device_type_id: device_type_id
        )
      rescue => e
        Rails.logger.error "Error fetching predefined presets: #{e.message}"
        failure("Failed to load predefined presets: #{e.message}")
      end
    end

    def get_user_presets(device_type_id)
      begin
        presets = Preset.where(
          user_id: @user.id,
          device_type_id: device_type_id,
          is_user_defined: true
        ).order(created_at: :desc)

        success(
          presets: presets,
          count: presets.count,
          device_type_id: device_type_id,
          user_id: @user.id
        )
      rescue => e
        Rails.logger.error "Error fetching user presets: #{e.message}"
        failure("Failed to load user presets: #{e.message}")
      end
    end

    def create_preset(device, preset_params)
      begin
        preset = Preset.new(
          device_type: device.device_type,
          user: @user,
          is_user_defined: true,
          name: preset_params[:name],
          settings: build_settings(preset_params)
        )

        if preset.save
          Rails.logger.info "Preset created: #{preset.name} for user #{@user.id}"
          
          success(
            preset: preset,
            message: 'Preset created successfully',
            settings_summary: summarize_settings(preset.settings)
          )
        else
          failure(
            "Failed to create preset: #{preset.errors.full_messages.join(', ')}",
            preset.errors.full_messages
          )
        end
      rescue => e
        Rails.logger.error "Error creating preset: #{e.message}"
        failure("Failed to create preset: #{e.message}")
      end
    end

    def update_preset(preset, preset_params)
      begin
        unless preset.editable_by?(@user)
          return failure("You don't have permission to edit this preset")
        end

        update_data = {
          name: preset_params[:name],
          settings: build_settings(preset_params)
        }.compact

        if preset.update(update_data)
          Rails.logger.info "Preset updated: #{preset.name} by user #{@user.id}"
          
          success(
            preset: preset,
            message: 'Preset updated successfully',
            settings_summary: summarize_settings(preset.settings),
            updated_fields: update_data.keys
          )
        else
          failure(
            "Failed to update preset: #{preset.errors.full_messages.join(', ')}",
            preset.errors.full_messages
          )
        end
      rescue => e
        Rails.logger.error "Error updating preset: #{e.message}"
        failure("Failed to update preset: #{e.message}")
      end
    end

    def delete_preset(preset)
      begin
        unless preset.editable_by?(@user)
          return failure("You don't have permission to delete this preset")
        end

        preset_name = preset.name
        
        if preset.destroy
          Rails.logger.info "Preset deleted: #{preset_name} by user #{@user.id}"
          
          success(
            message: 'Preset deleted successfully',
            deleted_preset: {
              id: preset.id,
              name: preset_name
            }
          )
        else
          failure("Failed to delete preset: #{preset.errors.full_messages.join(', ')}")
        end
      rescue => e
        Rails.logger.error "Error deleting preset: #{e.message}"
        failure("Failed to delete preset: #{e.message}")
      end
    end

    def validate_preset_settings(device_type_id, settings)
      begin
        device_type = DeviceType.find(device_type_id)
        validation_service = DeviceConfiguration::PresetValidationService.new(settings, device_type)
        validation_result = validation_service.call

        if validation_result.valid?
          success(
            valid: true,
            message: 'Settings validation passed',
            settings: settings,
            device_type: device_type.name
          )
        else
          success(
            valid: false,
            errors: validation_result.errors,
            warnings: validation_result.warnings,
            settings: settings,
            device_type: device_type.name
          )
        end
      rescue ActiveRecord::RecordNotFound
        failure(
          "Device type not found",
          [{
            field: 'device_type_id',
            message: 'Device type not found',
            code: 'DEVICE_TYPE_NOT_FOUND'
          }]
        )
      rescue => e
        Rails.logger.error "Error validating preset settings: #{e.message}"
        failure("Settings validation failed: #{e.message}")
      end
    end

    def bulk_apply_preset(preset, device_ids)
      begin
        unless can_apply_preset?(preset)
          return failure("You don't have permission to apply this preset")
        end

        devices = @user.devices.where(id: device_ids)
        if devices.count != device_ids.count
          return failure("Some devices not found or don't belong to you")
        end

        applied_devices = []
        failed_devices = []

        devices.each do |device|
          if device.device_type == preset.device_type
            if apply_preset_to_device(device, preset)
              applied_devices << device
            else
              failed_devices << { device: device, reason: 'Application failed' }
            end
          else
            failed_devices << { device: device, reason: 'Incompatible device type' }
          end
        end

        success(
          message: "Preset applied to #{applied_devices.count} devices",
          applied_devices: applied_devices.map { |d| { id: d.id, name: d.name } },
          failed_devices: failed_devices.map { |f| { id: f[:device].id, name: f[:device].name, reason: f[:reason] } },
          preset_name: preset.name
        )
      rescue => e
        Rails.logger.error "Error applying preset to devices: #{e.message}"
        failure("Failed to apply preset: #{e.message}")
      end
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

    def summarize_settings(settings)
      summary = {
        categories: [],
        total_configurations: 0
      }

      settings.each do |key, value|
        case key.to_s
        when 'lights'
          summary[:categories] << 'lighting_control'
          summary[:total_configurations] += value.keys.count
        when 'spray'
          summary[:categories] << 'spray_control'
          summary[:total_configurations] += value.keys.count
        when /pump\d+/
          summary[:categories] << 'pump_control' unless summary[:categories].include?('pump_control')
          summary[:total_configurations] += value.keys.count
        end
      end

      summary[:categories].uniq!
      summary
    end

    def can_apply_preset?(preset)
      # User can apply their own presets or system presets
      preset.user_id.nil? || preset.user_id == @user.id
    end

    def apply_preset_to_device(device, preset)
      # This would integrate with your device communication system
      # For now, just update the device's current settings
      begin
        device.update!(current_preset_id: preset.id, settings: preset.settings)
        
        # Queue a job to send settings to the actual device
        DeviceCommunication::ApplyPresetJob.perform_later(device.id, preset.settings)
        
        true
      rescue => e
        Rails.logger.error "Failed to apply preset to device #{device.id}: #{e.message}"
        false
      end
    end
  end
end