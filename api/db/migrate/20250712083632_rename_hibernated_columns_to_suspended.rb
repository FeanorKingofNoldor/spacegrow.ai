# db/migrate/20250712_rename_hibernated_columns_to_suspended.rb
class RenameHibernatedColumnsToSuspended < ActiveRecord::Migration[7.1]
  def up
    # Rename hibernated columns to suspended columns
    rename_column :devices, :hibernated_at, :suspended_at
    rename_column :devices, :hibernated_reason, :suspended_reason
    
    # Note: grace_period_ends_at stays the same - it's generic enough
    
    puts "✅ Renamed hibernated_* columns to suspended_* columns"
  end

  def down
    # Rollback: rename suspended columns back to hibernated columns  
    rename_column :devices, :suspended_at, :hibernated_at
    rename_column :devices, :suspended_reason, :hibernated_reason
    
    puts "⏪ Rolled back: renamed suspended_* columns back to hibernated_* columns"
  end
end