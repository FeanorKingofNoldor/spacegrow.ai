class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :status
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.string :interval, default: 'month'
      
      t.timestamps
    end

    add_index :subscriptions, :stripe_customer_id
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :status
  end
end