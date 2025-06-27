class AddCurrentStatusToDeviceSensors < ActiveRecord::Migration[7.1]
  def change
    add_column :device_sensors, :current_status, :string
  end
end
