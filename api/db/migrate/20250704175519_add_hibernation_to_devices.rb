# Generate this migration:
# rails generate migration AddsuspensionToDevices suspended_at:datetime suspended_reason:string grace_period_ends_at:datetime

class AddsuspensionToDevices < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :suspended_at, :datetime
    add_column :devices, :suspended_reason, :string
    add_column :devices, :grace_period_ends_at, :datetime
    
    # Add indexes for better query performance
    add_index :devices, :suspended_at
    add_index :devices, [:user_id, :suspended_at]
    add_index :devices, :grace_period_ends_at
    
    # Also add disabled tracking fields if not already present
    add_column :devices, :disabled_at, :datetime unless column_exists?(:devices, :disabled_at)
    add_column :devices, :disabled_reason, :string unless column_exists?(:devices, :disabled_reason)
    add_column :devices, :previous_status, :string unless column_exists?(:devices, :previous_status)
    
    add_index :devices, :disabled_at unless index_exists?(:devices, :disabled_at)
  end
end