class AddInventoryToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :stock_quantity, :integer, default: 0, null: false
    add_column :products, :featured, :boolean, default: false, null: false
    add_column :products, :detailed_description, :text
    add_column :products, :low_stock_threshold, :integer, default: 5, null: false
    
    # Add indexes for performance
    add_index :products, :stock_quantity
    add_index :products, :featured
    
    # Set default stock for existing products
    reversible do |dir|
      dir.up do
        # Set reasonable default stock for existing products
        Product.update_all(stock_quantity: 50, featured: false, low_stock_threshold: 5)
        
        # Make first few products featured
        Product.limit(3).update_all(featured: true)
      end
    end
  end
end