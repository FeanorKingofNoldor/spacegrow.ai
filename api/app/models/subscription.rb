# app/models/subscription.rb
class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan
  has_many :subscription_devices, dependent: :destroy
  has_many :devices, through: :subscription_devices

  # Constants
  STATUSES = %w[active past_due canceled pending].freeze

  # Validations
  validates :status, inclusion: { in: STATUSES }

  # Callbacks
  after_save :handle_status_change, if: :saved_change_to_status?

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :past_due, -> { where(status: 'past_due') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :pending, -> { where(status: 'pending') }

  # Calculate device limits
  def device_limit
    plan.device_limit + additional_device_slots
  end

  def can_add_device?
    active? && devices.count < device_limit
  end

  def add_device(device)
    return false unless can_add_device?

    subscription_devices.create!(
      device: device,
      monthly_cost: calculate_device_cost
    )
  end

  def remove_device(device)
    subscription_devices.find_by(device: device)&.destroy
  end

  def remove_specific_device(device_id)
    device = devices.find_by(id: device_id)

    raise 'Device not found' unless device

    device.activation_token&.update!(expires_at: Time.current)

    device_name = device.name
    device.destroy

    decrement!(:additional_device_slots) if additional_device_slots > 0

    "Device '#{device_name}' removed successfully. Additional device slots decremented by 1."
  end

  # Calculate costs
  def monthly_cost
    plan.price + subscription_devices.sum(:monthly_cost)
  end

  # Status helpers
  def active?
    status == 'active'
  end

  def past_due?
    status == 'past_due'
  end

  def canceled?
    status == 'canceled'
  end

  def pending?
    status == 'pending'
  end

  private

  def calculate_device_cost
    devices.count >= plan.device_limit ? Plan::ADDITIONAL_DEVICE_COST : 0
  end

  def handle_status_change
    DeviceActivationTokenService.expire_for_subscription(self)
  end
end
