# app/models/extra_device_slot.rb
class ExtraDeviceSlot < ApplicationRecord
  belongs_to :subscription

  validates :monthly_cost, presence: true, numericality: { equal_to: 5.00 }
  validates :status, inclusion: { in: %w[active cancelled] }

  scope :active, -> { where(status: 'active') }
  scope :cancelled, -> { where(status: 'cancelled') }

  before_validation :set_defaults, on: :create

  def active?
    status == 'active'
  end

  def cancelled?
    status == 'cancelled'
  end

  def cancel!
    update!(
      status: 'cancelled',
      cancelled_at: Time.current
    )
  end

  def monthly_cost_display
    "$#{monthly_cost}/month"
  end

  def description
    "Extra Device Slot ##{display_number}"
  end

  def display_number
    # Calculate position among active slots for this subscription
    subscription.extra_device_slots
                .where('created_at <= ?', created_at)
                .where(status: 'active')
                .count
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.monthly_cost ||= 5.00
    self.activated_at ||= Time.current
  end
end
