class CreatePresets < ActiveRecord::Migration[7.1]
  def change
    create_table :presets do |t|
      t.references :device_type, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :settings, default: {}, null: false
      t.boolean :is_user_defined, default: false, null: false
      t.timestamps
    end

    add_index :presets, [:device_type_id, :name], unique: true
  end
end