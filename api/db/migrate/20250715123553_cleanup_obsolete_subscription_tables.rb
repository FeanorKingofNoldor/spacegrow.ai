class CleanupObsoleteSubscriptionTables < ActiveRecord::Migration[7.1]
  def up
    # Remove SubscriptionDevice table (individual device cost tracking)
    drop_table :subscription_devices if table_exists?(:subscription_devices)
    
    # Remove ScheduledDeviceChange table (scheduled device operations)
    drop_table :scheduled_device_changes if table_exists?(:scheduled_device_changes)
    
    # Remove ScheduledPlanChange table (scheduled plan changes)  
    drop_table :scheduled_plan_changes if table_exists?(:scheduled_plan_changes)
    
    # Remove additional_device_slots column (replaced by ExtraDeviceSlot records)
    if column_exists?(:subscriptions, :additional_device_slots)
      remove_column :subscriptions, :additional_device_slots
      end
    end
    
    # Remove cancel_at_period_end (not needed in simplified system)
    if column_exists?(:subscriptions, :cancel_at_period_end)
      remove_column :subscriptions, :cancel_at_period_end  
    end
    
    puts "✅ Cleaned up obsolete subscription tables and columns"
  end