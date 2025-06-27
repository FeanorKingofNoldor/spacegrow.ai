class CreateSensorData < ActiveRecord::Migration[7.1]
  def change
    create_table :sensor_data do |t|
      t.references :device_sensor, null: false, foreign_key: true
      t.datetime :timestamp, null: false
      t.float :value, null: false
      t.boolean :is_valid

      t.timestamps
    end

    add_index :sensor_data, :timestamp
    add_index :sensor_data, [:device_sensor_id, :timestamp]
  end
end