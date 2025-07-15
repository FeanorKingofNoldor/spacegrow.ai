# app/controllers/concerns/preset_json_handling.rb
module PresetJsonHandling
  extend ActiveSupport::Concern

  private

  def preset_json(preset, include_details: false)
    json = {
      id: preset.id,
      name: preset.name,
      settings: preset.settings,
      device_type_id: preset.device_type_id,
      is_user_defined: preset.is_user_defined,
      created_at: preset.created_at
    }

    if include_details
      json.merge!({
        user_timezone: current_user.timezone,
        device_type: {
          id: preset.device_type.id,
          name: preset.device_type.name,
          configuration: preset.device_type.configuration
        },
        formatted_settings: preset.formatted_settings,
        settings_summary: preset.settings_summary
      })
    end

    json
  end

  def presets_collection_json(presets)
    presets.map { |preset| preset_json(preset) }
  end
end