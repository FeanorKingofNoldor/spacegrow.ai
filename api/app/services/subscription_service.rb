# app/services/subscription_service.rb
class SubscriptionService
  def self.create_subscription(user:, plan:, interval: 'month')
    old_plan = user.subscription&.plan
    user.subscription&.update!(status: 'canceled')

    subscription = Subscription.create!(
      user: user,
      plan: plan,
      status: 'active',
      interval: interval,
      current_period_start: Time.current,
      current_period_end: interval == 'month' ? 1.month.from_now : 1.year.from_now
    )

    if subscription.persisted?
      # Map plan name to role
      role = plan.name == 'Basic' ? 'user' : 'pro'
      user.update!(role: role)
      handle_subscription_change(user, old_plan, plan)
    end

    subscription
  end

  def self.cancel_subscription(subscription)
    subscription.update!(status: 'canceled')
  end

  def self.add_device(subscription:, device:)
    return false unless subscription.can_add_device?

    monthly_cost = calculate_device_cost(subscription)
    subscription.subscription_devices.create!(
      device: device,
      monthly_cost: monthly_cost
    )
  end

  private

  def self.handle_subscription_change(user, old_plan, new_plan)
    return unless old_plan # No previous plan, nothing to migrate

    if new_plan.base_device_count < old_plan.base_device_count
      # Downgrading - need to handle excess devices
      excess_count = old_plan.base_device_count - new_plan.base_device_count

      # Get the excess devices (oldest first)
      excess_devices = user.devices
                           .order(created_at: :asc)
                           .limit(excess_count)

      excess_devices.each do |device|
        # Either convert to paid additional device or disable
        if user.subscription.can_add_device?
          add_device(subscription: user.subscription, device: device)
        else
          device.update!(status: 'disabled')
        end
      end
    else
      # Upgrading or staying the same
      user.devices.limit(new_plan.base_device_count).each do |device|
        device.update!(status: 'pending')
      end

      # Handle any devices beyond the base limit as additional paid devices
      remaining_devices = user.devices.offset(new_plan.base_device_count)
      remaining_devices.each do |device|
        add_device(subscription: user.subscription, device: device)
      end
    end
  end

  def self.calculate_device_cost(subscription)
    return 0 if subscription.devices.count < subscription.plan.base_device_count

    Plan::ADDITIONAL_DEVICE_COST
  end
end
