class RemoveStatusFromSensorData < ActiveRecord::Migration[7.0]
  def change
    remove_column :sensor_data, :status, :string
  end
end