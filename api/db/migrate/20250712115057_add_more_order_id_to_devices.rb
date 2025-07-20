class AddMoreOrderIdToDevices < ActiveRecord::Migration[7.1]
  def change
    add_index :devices, :order_id
    add_foreign_key :devices, :orders, on_delete: :nullify
  end
end