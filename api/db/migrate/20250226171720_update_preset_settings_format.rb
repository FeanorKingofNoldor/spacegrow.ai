# db/migrate/[timestamp]_update_preset_settings_format.rb
class UpdatePresetSettingsFormat < ActiveRecord::Migration[7.1]
  def up
    Preset.all.each do |preset|
      settings = preset.settings
      next unless settings.present?

      new_settings = {}
      
      # Handle Environmental Monitor V1 presets
      if preset.device_type&.name == 'Environmental Monitor V1'
        if settings['lights_schedule']
          on_at, off_at = settings['lights_schedule'].split('-')
          new_settings['lights'] = { 'on_at' => on_at || 'N/A', 'off_at' => off_at || 'N/A' }
        end
        if settings['spray']
          new_settings['spray'] = {
            'on_for' => settings['spray']['duration'] || 0,
            'off_for' => settings['spray']['frequency'] || 0
          }
        end
      # Preserve Liquid Monitor V1 pump settings as-is
      elsif preset.device_type&.name == 'Liquid Monitor V1'
        new_settings = settings # No change needed for pumps
      end

      preset.update!(settings: new_settings) if new_settings.present?
    end
  end

  def down
    # Reverse logic if needed (optional, since old format is less structured)
    Preset.all.each do |preset|
      settings = preset.settings
      next unless settings.present?

      old_settings = {}
      
      if preset.device_type&.name == 'Environmental Monitor V1'
        if settings['lights']
          old_settings['lights'] = 'on'
          old_settings['lights_schedule'] = "#{settings['lights']['on_at']}-#{settings['lights']['off_at']}"
        end
        if settings['spray']
          old_settings['spray'] = {
            'state' => 'on',
            'duration' => settings['spray']['on_for'],
            'frequency' => settings['spray']['off_for']
          }
        end
      elsif preset.device_type&.name == 'Liquid Monitor V1'
        old_settings = settings # No change needed
      end

      preset.update!(settings: old_settings) if old_settings.present?
    end
  end
end