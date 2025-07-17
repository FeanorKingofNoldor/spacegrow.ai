# db/migrate/[timestamp]_add_payment_processing_fields_to_orders.rb
class AddPaymentProcessingFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :payment_completed_at, :datetime
    add_column :orders, :payment_failed_at, :datetime
    add_column :orders, :payment_failure_reason, :text
    add_column :orders, :retry_strategy, :string
    add_column :orders, :retry_reason, :text
    add_column :orders, :stripe_payment_intent_id, :string
    add_column :orders, :stripe_session_id, :string
    add_column :orders, :cancelled_at, :datetime
    add_column :orders, :cancellation_reason, :string
    
    # Add indexes for performance
    add_index :orders, :payment_completed_at
    add_index :orders, :payment_failed_at
    add_index :orders, :stripe_payment_intent_id
    add_index :orders, :stripe_session_id
    add_index :orders, :cancelled_at
    
    # Add index for retry strategy filtering
    add_index :orders, [:status, :retry_strategy]
  end
end