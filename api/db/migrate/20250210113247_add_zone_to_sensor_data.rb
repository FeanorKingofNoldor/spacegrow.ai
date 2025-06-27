class AddZoneToSensorData < ActiveRecord::Migration[7.1]
  def change
    add_column :sensor_data, :zone, :string
  end
end
