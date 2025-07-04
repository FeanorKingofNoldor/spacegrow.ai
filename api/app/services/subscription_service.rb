# app/services/subscription_service.rb
class SubscriptionService
  class << self
    def create_subscription(user:, plan:, interval: 'month')
      ActiveRecord::Base.transaction do
        # Cancel any existing active subscriptions
        user.subscriptions.where(status: 'active').update_all(
          status: 'canceled',
          cancel_at_period_end: false,
          updated_at: Time.current
        )

        subscription = Subscription.create!(
          user: user,
          plan: plan,
          status: 'active',
          interval: interval,
          current_period_start: Time.current,
          current_period_end: interval == 'month' ? 1.month.from_now : 1.year.from_now
        )

        if subscription.persisted?
          role = plan.name == 'Basic' ? 'user' : 'pro'
          user.update!(role: role)
          handle_subscription_change(user, nil, plan)
        end

        subscription
      end
    end

    def preview_plan_change(user:, target_plan:, target_interval: 'month')
      analyzer = PlanChangeAnalyzer.new(
        user: user,
        target_plan: target_plan,
        target_interval: target_interval
      )
      
      analyzer.analyze
    end

    def change_plan_with_strategy(user:, target_plan:, target_interval: 'month', strategy:, selected_device_ids: [])
      preview = preview_plan_change(user: user, target_plan: target_plan, target_interval: target_interval)
      
      case preview[:change_type]
      when 'current'
        raise StandardError, "You are already subscribed to this plan with this billing interval"
      when 'new_subscription'
        return create_subscription(user: user, plan: target_plan, interval: target_interval)
      end

      case strategy
      when 'immediate'
        execute_immediate_change(user, target_plan, target_interval)
      when 'immediate_with_selection'
        execute_immediate_change_with_selection(user, target_plan, target_interval, selected_device_ids)
      when 'end_of_period'
        schedule_plan_change(user, target_plan, target_interval)
      when 'pay_for_extra'
        execute_change_with_extra_devices(user, target_plan, target_interval)
      else
        raise ArgumentError, "Unknown strategy: #{strategy}"
      end
    end

    def schedule_plan_change(user, target_plan, target_interval)
      subscription = user.active_subscription || user.subscription
      end_date = subscription.current_period_end

      ScheduledPlanChange.create!(
        subscription: subscription,
        target_plan: target_plan,
        target_interval: target_interval,
        scheduled_for: end_date,
        status: 'pending'
      )

      ScheduledPlanChangeJob.set(wait_until: end_date).perform_later(subscription.id, target_plan.id, target_interval)

      {
        status: 'scheduled',
        effective_date: end_date,
        current_plan: subscription.plan.name,
        target_plan: target_plan.name,
        message: "Plan change scheduled for #{end_date.strftime('%B %d, %Y')}"
      }
    end

    def cancel_subscription(subscription)
      subscription.update!(status: 'canceled')
    end

    def add_device(subscription:, device:)
      return false unless subscription.can_add_device?

      monthly_cost = calculate_device_cost(subscription)
      subscription.subscription_devices.create!(
        device: device,
        monthly_cost: monthly_cost
      )
    end

    private

    def execute_immediate_change(user, target_plan, target_interval)
      old_plan = user.active_subscription&.plan || user.subscription&.plan
      subscription = user.active_subscription || user.subscription

      subscription.update!(
        plan: target_plan,
        interval: target_interval
      )

      role = target_plan.name == 'Basic' ? 'user' : 'pro'
      user.update!(role: role)

      handle_subscription_change(user, old_plan, target_plan)

      {
        status: 'completed',
        subscription: subscription,
        message: "Successfully changed to #{target_plan.name} plan"
      }
    end

    def execute_immediate_change_with_selection(user, target_plan, target_interval, selected_device_ids)
      validate_device_selection(user, target_plan, selected_device_ids)

      result = execute_immediate_change(user, target_plan, target_interval)

      unselected_devices = user.devices.active.where.not(id: selected_device_ids)
      DeviceManagementService.disable_devices(unselected_devices.pluck(:id))

      result[:disabled_devices] = unselected_devices.count
      result[:message] = "Plan changed successfully. #{unselected_devices.count} devices disabled."

      result
    end

    def execute_change_with_extra_devices(user, target_plan, target_interval)
      old_plan = user.active_subscription&.plan || user.subscription&.plan
      subscription = user.active_subscription || user.subscription
      
      current_device_count = user.devices.active.count
      extra_slots_needed = [current_device_count - target_plan.device_limit, 0].max

      subscription.update!(
        plan: target_plan,
        interval: target_interval,
        additional_device_slots: extra_slots_needed
      )

      role = target_plan.name == 'Basic' ? 'user' : 'pro'
      user.update!(role: role)

      extra_cost = extra_slots_needed * Plan::ADDITIONAL_DEVICE_COST

      {
        status: 'completed',
        subscription: subscription,
        extra_device_slots: extra_slots_needed,
        extra_monthly_cost: extra_cost,
        message: "Plan changed with #{extra_slots_needed} additional device slots ($#{extra_cost}/month extra)"
      }
    end

    def handle_subscription_change(user, old_plan, new_plan)
      return unless new_plan

      current_active_devices = user.devices.active.count

      if new_plan.device_limit >= current_active_devices
        user.devices.pending.limit(new_plan.device_limit - current_active_devices).each do |device|
          device.update!(status: 'active')
        end
      else
        Rails.logger.info "Device selection for downgrade should be handled by specific strategy methods"
      end
    end

    def validate_device_selection(user, target_plan, selected_device_ids)
      if selected_device_ids.length != target_plan.device_limit
        raise ArgumentError, "Must select exactly #{target_plan.device_limit} devices"
      end

      user_device_ids = user.devices.active.pluck(:id)
      invalid_ids = selected_device_ids - user_device_ids
      
      if invalid_ids.any?
        raise ArgumentError, "Invalid device IDs: #{invalid_ids.join(', ')}"
      end
    end

    def calculate_device_cost(subscription)
      return 0 if subscription.devices.count < subscription.plan.device_limit

      Plan::ADDITIONAL_DEVICE_COST
    end
  end
end