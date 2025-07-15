class CreateExtraDeviceSlots < ActiveRecord::Migration[7.1]
  def change
    create_table :extra_device_slots do |t|
      t.references :subscription, null: false, foreign_key: true
      t.decimal :monthly_cost, precision: 10, scale: 2, null: false, default: 5.00
      t.string :status, null: false, default: 'active'
      t.datetime :activated_at, null: false
      t.datetime :cancelled_at
      t.timestamps
    end

    add_index :extra_device_slots, [:subscription_id, :status]
    add_index :extra_device_slots, :activated_at
  end
end