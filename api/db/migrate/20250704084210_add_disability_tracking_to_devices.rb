# db/migrate/add_disability_tracking_to_devices.rb
class AddDisabilityTrackingToDevices < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :disabled_reason, :string
    add_column :devices, :disabled_at, :datetime
    add_column :devices, :previous_status, :string
    
    # Add index for performance on recently_disabled scope
    add_index :devices, [:status, :disabled_at], name: 'index_devices_on_status_and_disabled_at'
    
    # Add index for disabled_reason queries
    add_index :devices, :disabled_reason
  end
end