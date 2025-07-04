# db/migrate/enhance_subscriptions_table.rb  
class EnhanceSubscriptionsTable < ActiveRecord::Migration[7.0]
  def change
    # Add any missing columns that might be needed
    add_column :subscriptions, :cancel_at_period_end, :boolean, default: false unless column_exists?(:subscriptions, :cancel_at_period_end)
    add_column :subscriptions, :additional_device_slots, :integer, default: 0 unless column_exists?(:subscriptions, :additional_device_slots)
    
    # Add useful indexes
    add_index :subscriptions, [:user_id, :status] unless index_exists?(:subscriptions, [:user_id, :status])
    add_index :subscriptions, :current_period_end unless index_exists?(:subscriptions, :current_period_end)
  end
end