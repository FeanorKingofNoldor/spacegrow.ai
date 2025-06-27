# db/migrate/XXXXXX_create_products.rb
class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :stripe_price_id, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.references :device_type, null: true, foreign_key: true
      t.boolean :active, default: true

      t.timestamps

      t.index :active
    end
  end
end