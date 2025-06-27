class UpdatePresetsUniqueIndex < ActiveRecord::Migration[7.0]
  def change
    # Remove the old index
    remove_index :presets, name: "index_presets_on_device_type_id_and_name"

    # Add a new unique index including user_id, allowing nulls
    add_index :presets, [:device_type_id, :name, :user_id], 
              unique: true, 
              name: "index_presets_on_device_type_name_user", 
              where: "user_id IS NOT NULL"

    # Add a separate unique index for predefined presets (user_id IS NULL)
    add_index :presets, [:device_type_id, :name], 
              unique: true, 
              name: "index_presets_on_device_type_and_name_predefined", 
              where: "user_id IS NULL"
  end
end