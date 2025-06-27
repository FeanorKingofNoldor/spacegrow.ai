class AddSensorDataIndexes < ActiveRecord::Migration[7.1]
  def change
    # Main index for querying by time ranges and device_sensor
    add_index :sensor_data, [:device_sensor_id, :timestamp], 
              name: 'idx_sensor_data_device_time'
              
    # Index for time-based queries across all devices
    add_index :sensor_data, :timestamp, 
              name: 'idx_sensor_data_timestamp'
              
    # Index for filtering valid/invalid readings
    add_index :sensor_data, [:is_valid, :timestamp],
              name: 'idx_sensor_data_validity_time'
              
    # Composite index for efficient sensor type lookups
    add_index :sensor_data, [:device_sensor_id, :timestamp, :is_valid],
              name: 'idx_sensor_data_device_time_valid'
  end
end