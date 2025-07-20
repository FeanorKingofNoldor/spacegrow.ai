class AddCancelAtPeriodEndToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :cancel_at_period_end, :boolean, default: false
  end
end