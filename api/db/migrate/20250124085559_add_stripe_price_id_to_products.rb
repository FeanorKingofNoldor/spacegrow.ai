class AddStripePriceIdToProducts < ActiveRecord::Migration[7.1]
  def change
    change_column :products, :stripe_price_id, :string, null: true
  end
end
