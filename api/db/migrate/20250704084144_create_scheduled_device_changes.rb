# db/migrate/xxx_create_scheduled_device_changes.rb
class CreateScheduledDeviceChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_device_changes do |t|
      t.references :user, null: false, foreign_key: true
      t.json :device_ids, null: false
      t.string :action, null: false
      t.datetime :scheduled_for, null: false
      t.string :status, default: 'pending', null: false
      t.string :reason
      t.datetime :executed_at
      t.text :error_message
      
      t.timestamps
    end
    
    add_index :scheduled_device_changes, [:status, :scheduled_for]
    add_index :scheduled_device_changes, [:user_id, :status]
  end
end