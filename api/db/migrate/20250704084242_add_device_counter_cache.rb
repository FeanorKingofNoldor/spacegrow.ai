# db/migrate/add_device_counter_cache.rb
class AddDeviceCounterCache < ActiveRecord::Migration[7.0] 
  def change
    add_column :users, :devices_count, :integer, default: 0 unless column_exists?(:users, :devices_count)
    
    # Populate the counter cache - fixed method
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          User.reset_counters(user.id, :devices)
        end
      end
    end
  end
end