class AllowNullStripeIdsInPlans < ActiveRecord::Migration[7.1]
  def change
    change_column_null :plans, :stripe_monthly_price_id, true
    change_column_null :plans, :stripe_yearly_price_id, true
  end
end
