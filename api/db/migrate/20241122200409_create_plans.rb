class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :stripe_monthly_price_id
      t.string :stripe_yearly_price_id
      t.integer :device_limit, null: false
      t.decimal :monthly_price, precision: 10, scale: 2, null: false
      t.decimal :yearly_price, precision: 10, scale: 2, null: false
      t.string :description

      t.timestamps
    end

    # Add indexes after the table is created
    add_index :plans, :stripe_monthly_price_id, unique: true
    add_index :plans, :stripe_yearly_price_id, unique: true
  end
end