# db/migrate/XXXXXX_create_orders.rb
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.decimal :total, precision: 10, scale: 2

      t.timestamps

      t.index :status
    end
  end
end