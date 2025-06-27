# db/migrate/XXXXXX_add_consecutive_missing_readings_to_device_sensors.rb
class AddConsecutiveMissingReadingsToDeviceSensors < ActiveRecord::Migration[7.1]
  def change
    add_column :device_sensors, :consecutive_missing_readings, :integer, default: 0, null: false
    add_index :device_sensors, :consecutive_missing_readings
  end
end