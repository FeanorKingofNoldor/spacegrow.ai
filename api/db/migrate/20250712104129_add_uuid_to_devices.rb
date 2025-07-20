# db/migrate/add_uuid_to_devices.rb
class AddUuidToDevices < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :uuid, :string
    add_index :devices, :uuid, unique: true
    
    # Also ensure we have api_key if missing
    add_column :devices, :api_key, :string unless column_exists?(:devices, :api_key)
    add_index :devices, :api_key, unique: true unless index_exists?(:devices, :api_key)
  end
end