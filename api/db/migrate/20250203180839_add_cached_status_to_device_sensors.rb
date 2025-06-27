class AddCachedStatusToDeviceSensors < ActiveRecord::Migration[7.1]
  def change
    add_column :device_sensors, :cached_status, :string
    add_column :device_sensors, :cached_status_expires_at, :datetime
  end
end
