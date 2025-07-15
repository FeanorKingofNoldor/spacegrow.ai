# app/controllers/concerns/subscription_json_handling.rb
module SubscriptionJsonHandling
  extend ActiveSupport::Concern

  private

  def plan_json(plan)
    {
      id: plan.id,
      name: plan.name,
      description: plan.description,
      device_limit: plan.device_limit,
      monthly_price: plan.monthly_price,
      yearly_price: plan.yearly_price,
      features: plan.features
    }
  end

  def subscription_json(subscription)
    {
      id: subscription.id,
      plan: plan_json(subscription.plan),
      status: subscription.status,
      interval: subscription.interval,
      device_limit: subscription.device_limit,
      additional_device_slots: subscription.additional_device_slots,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      device_counts: {
        total: subscription.total_devices_count,
        operational: subscription.operational_devices_count,
        suspended: subscription.suspended_devices_count
      }
    }
  end

  def device_json(device, include_suspension: false)
    json = {
      id: device.id,
      name: device.name,
      device_type: device.device_type.name,
      status: device.status,
      alert_status: device.alert_status,
      last_connection: device.last_connection,
      operational: device.operational?,
      suspended: device.suspended?,
      created_at: device.created_at,
      is_activated: device.active?,
      needs_activation: device.pending?
    }
    
    if include_suspension
      json.merge!({
        suspended_at: device.suspended_at,
        suspended_reason: device.suspended_reason,
        in_grace_period: device.in_grace_period?,
        grace_period_ends_at: device.grace_period_ends_at
      })
    end
    
    json
  end
end