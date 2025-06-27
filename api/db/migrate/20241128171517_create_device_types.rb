# db/migrate/XXXXXX_create_device_types.rb
class CreateDeviceTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :device_types do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :configuration, null: false, default: {}

      t.timestamps
      t.index :name, unique: true
      t.index :configuration, using: :gin
    end
  end
end