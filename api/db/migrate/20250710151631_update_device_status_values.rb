# db/migrate/[timestamp]_update_device_status_values.rb
class UpdateDeviceStatusValues < ActiveRecord::Migration[7.1]
  def up
    # Step 1: Update existing data to match new status scheme
    say "Updating device status values..."
    
    # suspended → suspended (devices over subscription limit)
    suspended_count = execute("UPDATE devices SET status = 'suspended' WHERE status = 'suspended'").cmd_tuples
    say "Updated #{suspended_count} suspended devices to suspended"
    
    # inactive → active (since operational scope includes inactive devices)
    # These are activated devices that aren't suspended, so they should be active
    inactive_count = execute("UPDATE devices SET status = 'active' WHERE status = 'inactive'").cmd_tuples  
    say "Updated #{inactive_count} inactive devices to active"
    
    # Step 2: Verify data integrity
    say "Verifying data..."
    
    # Check for any unexpected status values
    result = execute("SELECT DISTINCT status FROM devices WHERE status NOT IN ('pending', 'active', 'suspended', 'disabled')")
    unexpected_statuses = result.values.flatten
    
    if unexpected_statuses.any?
      say "WARNING: Found unexpected status values: #{unexpected_statuses.join(', ')}"
      say "These will need manual review before changing validations"
    else
      say "✅ All device statuses are now valid"
    end
    
    # Show summary
    status_counts = execute(<<~SQL).to_a
      SELECT status, COUNT(*) as count 
      FROM devices 
      GROUP BY status 
      ORDER BY status
    SQL
    
    say "Current device status distribution:"
    status_counts.each do |row|
      say "  #{row['status']}: #{row['count']} devices"
    end
  end

  def down
    # Reverse the migration
    say "Reverting device status values..."
    
    # suspended → suspended
    suspended_count = execute("UPDATE devices SET status = 'suspended' WHERE status = 'suspended'").cmd_tuples
    say "Reverted #{suspended_count} suspended devices to suspended"
    
    # Note: We don't revert active → inactive because we don't know which active devices 
    # were originally inactive. This is acceptable since the operational scope included 
    # both active and inactive anyway.
    
    say "✅ Migration reverted (note: active devices remain active)"
  end
end