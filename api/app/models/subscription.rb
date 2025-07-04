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

  # ✅ NEW: Hibernation-aware device limits
  def device_limit
    plan.device_limit + additional_device_slots
  end

  def operational_devices_count
    user.devices.operational.count
  end

  def hibernating_devices_count
    user.devices.hibernating.count
  end

  def total_devices_count
    user.devices.count
  end

  def can_add_device?
    active? && operational_devices_count < device_limit
  end

  # ✅ NEW: Core hibernation business logic - "Always Accept, Then Upsell"
  def activate_device!(device)
    if operational_devices_count < device_limit
      # Device can be operational
      {
        success: true,
        operational: true,
        hibernating: false,
        message: 'Device activated successfully',
        subscription_status: 'within_limit'
      }
    else
      # Over limit - hibernate least important device and provide upsell options
      hibernated_device = hibernate_least_important_device!
      
      # The new device goes into hibernation too
      device.hibernate!(reason: 'subscription_limit')
      
      {
        success: true,
        operational: false,
        hibernating: true,
        message: 'Device activated but hibernated due to subscription limits',
        subscription_status: 'over_limit',
        hibernated_device: {
          id: hibernated_device.id,
          name: hibernated_device.name
        },
        upsell_options: generate_upsell_options,
        grace_period_ends_at: device.grace_period_ends_at
      }
    end
  end

  # ✅ NEW: Smart hibernation - hibernate the least important device
  def hibernate_least_important_device!
    # Find the device with highest hibernation priority (least important)
    target_device = user.devices.operational
                        .select { |d| d.hibernation_priority_score }
                        .max_by(&:hibernation_priority_score)
    
    if target_device
      target_device.hibernate!(reason: 'subscription_limit_auto')
    end
    
    target_device
  end

  # ✅ NEW: Generate upsell options for over-limit scenarios
  def generate_upsell_options
    options = []
    
    # Option 1: Add device slots
    options << {
      type: 'add_slots',
      title: 'Add Device Slot',
      description: 'Add an extra device slot to your current plan',
      cost: Plan::ADDITIONAL_DEVICE_COST,
      billing: 'monthly',
      action: 'add_device_slots',
      devices_count: 1
    }
    
    # Option 2: Upgrade plan (if available)
    if plan.name == 'Basic'
      professional_plan = Plan.find_by(name: 'Professional')
      if professional_plan
        cost_difference = professional_plan.monthly_price - plan.monthly_price
        options << {
          type: 'upgrade_plan',
          title: 'Upgrade to Professional',
          description: "Increase your device limit to #{professional_plan.device_limit} devices",
          cost: cost_difference,
          billing: 'monthly',
          action: 'upgrade_plan',
          target_plan_id: professional_plan.id,
          new_device_limit: professional_plan.device_limit
        }
      end
    end
    
    # Option 3: Manage devices (free)
    options << {
      type: 'manage_devices',
      title: 'Manage Your Devices',
      description: 'Choose which devices to keep active and which to hibernate',
      cost: 0,
      billing: 'free',
      action: 'manage_devices'
    }
    
    options
  end

  # ✅ NEW: Wake up specific hibernated devices
  def wake_up_devices!(device_ids)
    devices_to_wake = user.devices.hibernating.where(id: device_ids)
    available_slots = device_limit - operational_devices_count
    
    if devices_to_wake.count > available_slots
      return {
        success: false,
        error: "Cannot wake #{devices_to_wake.count} devices. Only #{available_slots} slots available."
      }
    end
    
    woken_devices = []
    devices_to_wake.each do |device|
      device.wake_up!
      woken_devices << {
        id: device.id,
        name: device.name
      }
    end
    
    {
      success: true,
      woken_devices: woken_devices
    }
  end

  # ✅ NEW: Hibernate specific operational devices
  def hibernate_devices!(device_ids, reason: 'user_choice')
    devices_to_hibernate = user.devices.operational.where(id: device_ids)
    
    hibernated_devices = []
    devices_to_hibernate.each do |device|
      device.hibernate!(reason: reason)
      hibernated_devices << {
        id: device.id,
        name: device.name,
        hibernated_reason: reason
      }
    end
    
    {
      success: true,
      hibernated_devices: hibernated_devices
    }
  end

  # ✅ NEW: Get hibernation priorities for all user devices
  def hibernation_priorities
    user.devices.operational.map do |device|
      {
        device_id: device.id,
        device_name: device.name,
        score: device.hibernation_priority_score,
        last_connection: device.last_connection,
        created_at: device.created_at,
        alert_status: device.alert_status
      }
    end.sort_by { |d| -d[:score] } # Highest score first (most likely to be hibernated)
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
    device = user.devices.find_by(id: device_id)

    raise 'Device not found' unless device

    device.activation_token&.update!(expires_at: Time.current)

    device_name = device.name
    device.destroy

    decrement!(:additional_device_slots) if additional_device_slots > 0

    "Device '#{device_name}' removed successfully. Additional device slots decremented by 1."
  end

  # Calculate costs
  def monthly_cost
    plan.monthly_price + subscription_devices.sum(:monthly_cost)
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
    operational_devices_count >= plan.device_limit ? Plan::ADDITIONAL_DEVICE_COST : 0
  end

  def handle_status_change
    DeviceActivationTokenService.expire_for_subscription(self)
  end
end