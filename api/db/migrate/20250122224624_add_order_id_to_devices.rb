class AddOrderIdToDevices < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :order_id, :bigint
  end
end
