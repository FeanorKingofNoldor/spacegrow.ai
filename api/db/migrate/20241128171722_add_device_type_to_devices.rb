# db/migrate/XXXXXX_add_device_type_to_devices.rb
class AddDeviceTypeToDevices < ActiveRecord::Migration[7.1]
  def change
    add_reference :devices, :device_type, null: true, foreign_key: true
    
    # Add index for performance
    add_index :devices, [:device_type_id, :status]
  end
end