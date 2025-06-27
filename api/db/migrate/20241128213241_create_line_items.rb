# db/migrate/XXXXXX_create_line_items.rb
class CreateLineItems < ActiveRecord::Migration[7.1]
  def change
    create_table :line_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps

      t.index [:order_id, :product_id]
    end
  end
end