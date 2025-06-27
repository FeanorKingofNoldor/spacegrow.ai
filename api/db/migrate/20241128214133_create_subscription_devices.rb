# db/migrate/XXXXXX_create_subscription_devices.rb
class CreateSubscriptionDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_devices do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :device, null: false, foreign_key: true
      t.decimal :monthly_cost, precision: 10, scale: 2, null: false

      t.timestamps

      t.index [:subscription_id, :device_id], unique: true
    end
  end
end