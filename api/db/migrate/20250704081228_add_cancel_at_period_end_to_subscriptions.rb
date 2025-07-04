class AddCancelAtPeriodEndToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :cancel_at_period_end, :boolean, default: false
  end
end