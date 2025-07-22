# app/models/subscription.rb - ENHANCED WITH ADMIN FEATURES
class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan
  
  # ===== ONLY: Granular slot management =====
  has_many :extra_device_slots, dependent: :destroy
  
  # Constants
  STATUSES = %w[active past_due canceled pending].freeze

  # Validations
  validates :status, inclusion: { in: STATUSES }

  # Callbacks - Keep only role sync
  after_create :sync_user_role_with_plan
  after_update :sync_user_role_with_plan, if: :saved_change_to_plan_id?

  # ===== EXISTING SCOPES (KEPT AS-IS) =====
  scope :active, -> { where(status: 'active') }
  scope :past_due, -> { where(status: 'past_due') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :pending, -> { where(status: 'pending') }

  # ===== NEW ADMIN-FRIENDLY SCOPES =====
  scope :in_date_range, ->(range) { where(created_at: range) }
  scope :recent, -> { where(created_at: 24.hours.ago..) }

  # ===== NEW ADMIN ANALYTICS CLASS METHODS =====
  def self.analytics_for_period(period)
    date_range = DateRangeHelper.calculate_range(period)
    {
      total_active: active.count,
      total_past_due: past_due.count,
      total_canceled: canceled.count,
      new_subscriptions: in_date_range(date_range).count,
      cancellations: where(status: 'canceled', updated_at: date_range).count,
      mrr: active.joins(:plan).sum('plans.monthly_price'),
      avg_revenue_per_user: active.joins(:plan).average('plans.monthly_price')&.round(2) || 0
    }
  end

  def self.admin_overview(limit: 20)
    {
      recent_subscriptions: includes(:user, :plan).order(created_at: :desc).limit(limit).map(&:admin_summary),
      past_due_count: past_due.count,
      active_count: active.count,
      mrr: active.joins(:plan).sum('plans.monthly_price')
    }
  end

  # ===== SIMPLIFIED: Delegate to services (KEPT AS-IS) =====
  
  def device_limit
    # Always delegate to DeviceSlotManager for consistency
    Billing::DeviceSlotManager.new(user).total_slots
  end

  def operational_devices_count
    user.devices.operational.count
  end

  def suspended_devices_count
    user.devices.suspended.count
  end

  def total_devices_count
    user.devices.count
  end

  def can_add_device?
    active? && Billing::DeviceSlotManager.new(user).can_activate_device?
  end

  # ===== GRANULAR SLOT METHODS (KEPT AS-IS) =====
  
  def active_extra_slots_count
    extra_device_slots.active.count
  end
  
  def total_extra_slot_cost
    extra_device_slots.active.sum(:monthly_cost)
  end
  
  def monthly_cost
    plan.monthly_price + total_extra_slot_cost
  end
  
  # ===== DEVICE MANAGEMENT: Delegate to services (KEPT AS-IS) =====
  
  def activate_device(device)
    Billing::DeviceStateManager.new(user).activate_device(device)
  end

  def suspend_devices(device_ids, reason: 'user_choice')
    Billing::DeviceStateManager.new(user).suspend_devices(device_ids, reason: reason)
  end

  def wake_devices(device_ids)
    Billing::DeviceStateManager.new(user).wake_devices(device_ids)
  end

  # ===== SLOT MANAGEMENT: Delegate to services (KEPT AS-IS) =====
  
  def purchase_extra_slot
    Billing::ExtraSlotManager.new(user).purchase_slot
  end

  def cancel_extra_slot(slot_id)
    Billing::ExtraSlotManager.new(user).cancel_slot(slot_id)
  end

  def list_extra_slots
    Billing::ExtraSlotManager.new(user).list_user_slots
  end

  # ===== PLAN CHANGES: Delegate to services (KEPT AS-IS) =====
  
  def preview_plan_change(target_plan, interval = 'month')
    Billing::PlanChangeWorkflow.new(user).preview_plan_change(target_plan, interval)
  end

  def execute_plan_change(target_plan, interval = 'month', options = {})
    Billing::PlanChangeWorkflow.new(user).execute_plan_change(target_plan, interval, options)
  end

  # ===== STATUS HELPERS (KEPT AS-IS) =====
  
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

  # ===== NEW ADMIN HELPER METHODS =====
  def admin_summary
    {
      id: id,
      user_email: user.email,
      plan_name: plan&.name,
      status: status,
      monthly_cost: monthly_cost,
      device_count: user.devices.count,
      created_at: created_at,
      current_period_end: current_period_end
    }
  end

  def admin_actions_available
    actions = []
    actions << 'update_status' unless %w[canceled].include?(status)
    actions << 'force_plan_change' if active?
    actions << 'manage_devices' if user.devices.any?
    actions
  end

  # ===== SUMMARY METHODS (KEPT AS-IS) =====
  
  def billing_summary
    {
      plan: {
        name: plan.name,
        base_cost: plan.monthly_price,
        device_limit: plan.device_limit
      },
      extra_slots: {
        count: active_extra_slots_count,
        cost: total_extra_slot_cost
      },
      total_monthly_cost: monthly_cost,
      device_usage: {
        operational: operational_devices_count,
        total_limit: device_limit,
        available: device_limit - operational_devices_count
      }
    }
  end

  private

  def sync_user_role_with_plan
    return if user.admin?
    
    new_role = plan.user_role
    
    if user.role != new_role
      Rails.logger.info "🔄 Syncing user #{user.id} role from '#{user.role}' to '#{new_role}' (plan: #{plan.name})"
      user.update!(role: new_role)
    end
  end
end