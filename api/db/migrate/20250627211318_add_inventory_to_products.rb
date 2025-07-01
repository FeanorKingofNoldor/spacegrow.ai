class AddInventoryToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :stock_quantity, :integer, default: 1000, null: false
    add_column :products, :low_stock_threshold, :integer, default: 10, null: false
    add_column :products, :featured, :boolean, default: false, null: false
    add_column :products, :detailed_description, :text

    add_index :products, :stock_quantity
    add_index :products, :featured
  end
end