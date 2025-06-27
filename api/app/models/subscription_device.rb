# app/models/subscription_device.rb
class SubscriptionDevice < ApplicationRecord
  belongs_to :subscription
  belongs_to :device

  validates :monthly_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :device_id, uniqueness: { scope: :subscription_id }
end