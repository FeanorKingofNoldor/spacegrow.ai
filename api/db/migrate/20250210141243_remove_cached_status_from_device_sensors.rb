class RemoveCachedStatusFromDeviceSensors < ActiveRecord::Migration[7.1]
  def change
    remove_column :device_sensors, :cached_status, :string
    remove_column :device_sensors, :cached_status_expires_at, :datetime
  end
end
