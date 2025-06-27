class AddDeviceIdToPresets < ActiveRecord::Migration[7.1]
  def change
    add_reference :presets, :device, null: true, foreign_key: true
    add_index :presets, [:device_type_id, :device_id, :name, :user_id], unique: true, where: "(user_id IS NOT NULL)", name: "index_presets_on_type_device_name_user"
  end
end