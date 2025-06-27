class CreateDeviceSensors < ActiveRecord::Migration[7.1]
  def change
    create_table :device_sensors do |t|
      t.references :device, null: false, foreign_key: true
      t.references :sensor_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :device_sensors, [:device_id, :sensor_type_id], unique: true
  end
end