# app/models/plan.rb
class Plan < ApplicationRecord
  has_many :subscriptions
  has_many :users, through: :subscriptions

  validates :name, presence: true, uniqueness: true
  validates :device_limit, presence: true, numericality: { greater_than: 0 }
  validates :monthly_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :yearly_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_monthly_price_id, presence: true, unless: -> { Rails.env.development? || Rails.env.test? }
  validates :stripe_yearly_price_id, presence: true, unless: -> { Rails.env.development? || Rails.env.test? }

  ADDITIONAL_DEVICE_COST = 5.00

  FEATURES = {
    'Basic' => [
      'Basic monitoring',
      'Standard support',
      'Email alerts',
      'API access'
    ],
    'PRO' => [
      'Advanced monitoring',
      'Priority support',
      'API access',
      'Custom integrations',
      'Data analytics'
    ]
  }.freeze

  def self.default_plan
    find_by(name: 'Basic')
  end

  def features
    FEATURES[name] || []
  end

  def pro?
    name.downcase == 'pro'
  end
end
