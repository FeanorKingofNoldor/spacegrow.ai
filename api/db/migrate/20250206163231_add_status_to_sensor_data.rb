class AddStatusToSensorData < ActiveRecord::Migration[7.1]
  def change
    add_column :sensor_data, :status, :string
  end
end
