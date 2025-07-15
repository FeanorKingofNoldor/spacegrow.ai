# app/models/concerns/suspendable.rb
module Suspendable
  extend ActiveSupport::Concern

  included do
    scope :suspended, -> { where(status: 'suspended') }
    scope :active, -> { where(status: 'active') }
    scope :operational, -> { where(status: 'active') }
  end

  def suspend!(reason: 'Manual suspension', grace_period_days: 30)
    update!(
      status: 'suspended',
      suspended_at: Time.current,
      suspended_reason: reason,
      grace_period_ends_at: grace_period_days.days.from_now
    )
  end

  def wake!
    update!(
      status: 'active',
      suspended_at: nil,
      suspended_reason: nil,
      grace_period_ends_at: nil
    )
  end

  def suspended?
    status == 'suspended'
  end

  def operational?
    status == 'active'
  end

  def in_grace_period?
    suspended? && grace_period_ends_at && Time.current < grace_period_ends_at
  end
end