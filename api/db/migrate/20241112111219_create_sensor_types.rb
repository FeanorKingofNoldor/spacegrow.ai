class CreateSensorTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :sensor_types do |t|
      t.string :name, null: false
      t.string :unit, null: false
      t.float :min_value, null: false
      t.float :max_value, null: false
      
      # Error ranges
      t.float :error_low_min, null: false
      t.float :error_low_max, null: false
      t.float :error_high_min, null: false
      t.float :error_high_max, null: false
      
      # Warning ranges
      t.float :warning_low_min, null: false
      t.float :warning_low_max, null: false
      t.float :warning_high_min, null: false
      t.float :warning_high_max, null: false
      
      # Normal range
      t.float :normal_min, null: false
      t.float :normal_max, null: false

      t.timestamps
    end

    add_index :sensor_types, :name, unique: true
  end
end