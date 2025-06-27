class AddAdditionalDeviceSlotsToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :additional_device_slots, :integer, default: 0, null: false
  end
end
