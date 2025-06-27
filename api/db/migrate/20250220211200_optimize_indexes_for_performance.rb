class OptimizeIndexesForPerformance < ActiveRecord::Migration[7.1]
  def change
    # Drop redundant sensor_data index (keep the DESC version)
    remove_index :sensor_data, name: "index_sensor_data_on_device_sensor_id_and_timestamp"
    # Keep index_sensor_data_on_device_sensor_and_timestamp with DESC ordering

    # Add composite indexes for devices aggregation
    add_index :devices, [:user_id, :status], name: "index_devices_on_user_id_and_status"
    add_index :devices, [:user_id, :alert_status], name: "index_devices_on_user_id_and_alert_status"

    # Ensure sensor_data indexes are optimal (already present, just confirming)
    # add_index :sensor_data, :device_sensor_id # Already exists
    # add_index :sensor_data, [:device_sensor_id, :timestamp], order: { timestamp: :desc } # Already exists
  end
end