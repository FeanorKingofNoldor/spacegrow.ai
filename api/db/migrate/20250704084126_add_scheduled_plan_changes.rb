# db/migrate/add_scheduled_plan_changes.rb
class AddScheduledPlanChanges < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_plan_changes do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :target_plan, null: false, foreign_key: { to_table: :plans }
      t.string :target_interval, null: false, default: 'month'
      t.datetime :scheduled_for, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :completed_at
      t.datetime :canceled_at
      t.text :error_message
      t.text :notes
      
      t.timestamps
    end
    
    add_index :scheduled_plan_changes, [:subscription_id, :status]
    add_index :scheduled_plan_changes, [:scheduled_for, :status]
  end
end