module SubscriptionManagement
  class SubscriptionService < ApplicationService
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

      # ✅ FIXED: Updated strategy parameter handling to match frontend names
      def change_plan_with_strategy(user:, target_plan:, target_interval: 'month', strategy:, selected_device_ids: [])
        preview = preview_plan_change(user: user, target_plan: target_plan, target_interval: target_interval)
        
        case preview[:change_type]
        when 'current'
          raise StandardError, "You are already subscribed to this plan with this billing interval"
        when 'new_subscription'
          return create_subscription(user: user, plan: target_plan, interval: target_interval)
        end

        # ✅ FIXED: Updated strategy names to match frontend
        case strategy
        when 'immediate'
          execute_immediate_change(user, target_plan, target_interval)
        when 'immediate_with_selection'  # ✅ FIXED: Changed from 'immediate_with_device_selection'
          execute_immediate_change_with_selection(user, target_plan, target_interval, selected_device_ids)
        when 'end_of_period'
          schedule_plan_change(user, target_plan, target_interval)
        when 'pay_for_extra'  # ✅ FIXED: Changed from 'pay_for_extra_devices'
          execute_change_with_extra_devices(user, target_plan, target_interval)
        when 'suspend_excess'  # ✅ NEW: Added missing strategy
          execute_change_with_suspension(user, target_plan, target_interval, selected_device_ids)
        else
          raise ArgumentError, "Unknown strategy: #{strategy}"
        end
      end

      def schedule_plan_change(user, target_plan, target_interval)
        workflow = Billing::PlanChangeWorkflow.new(user)
        result = workflow.preview_plan_change(target_plan, target_interval)
        
        if result[:success]
          {
            status: 'scheduled',
            effective_date: user.subscription.current_period_end,
            current_plan: user.subscription.plan.name,
            target_plan: target_plan.name,
            message: "Plan change will be processed with the new billing system",
            workflow_data: result
          }
        else
          {
            status: 'error',
            message: result[:error] || 'Failed to schedule plan change'
          }
        end
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

      # ✅ FIXED: Updated parameter name to selected_device_ids
      def execute_immediate_change_with_selection(user, target_plan, target_interval, selected_device_ids)
        validate_device_selection(user, target_plan, selected_device_ids)

        result = execute_immediate_change(user, target_plan, target_interval)

        unselected_devices = user.devices.operational.where.not(id: selected_device_ids)  # ✅ UPDATED: Uses new operational scope
        
        # ✅ ENHANCED: Use suspension instead of disabling
        suspended_devices = []
        unselected_devices.each do |device|
          device.suspend!(reason: 'plan_change')  # Uses updated suspend! method
          suspended_devices << device
        end

        result[:suspended_devices] = suspended_devices.count
        result[:message] = "Plan changed successfully. #{suspended_devices.count} devices suspended."

        result
      end

      def execute_change_with_extra_devices(user, target_plan, target_interval)
        old_plan = user.active_subscription&.plan || user.subscription&.plan
        subscription = user.active_subscription || user.subscription
        
        current_device_count = user.devices.operational.count  # ✅ ENHANCED: Use operational count
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

      # ✅ NEW: Added suspend_excess strategy implementation
      def execute_change_with_suspension(user, target_plan, target_interval, selected_device_ids)
        old_plan = user.active_subscription&.plan || user.subscription&.plan
        subscription = user.active_subscription || user.subscription
        
        # Validate that the selected devices exist and belong to the user
        devices_to_suspend = user.devices.operational.where(id: selected_device_ids)  # ✅ UPDATED: Uses new operational scope
        
        if devices_to_suspend.count != selected_device_ids.count
          invalid_ids = selected_device_ids - devices_to_suspend.pluck(:id)
          raise ArgumentError, "Invalid device IDs: #{invalid_ids.join(', ')}"
        end

        # Execute the plan change
        subscription.update!(
          plan: target_plan,
          interval: target_interval,
          additional_device_slots: 0
        )

        role = target_plan.name == 'Basic' ? 'user' : 'pro'
        user.update!(role: role)

        # suspend the selected devices
        suspended_devices = []
        devices_to_suspend.each do |device|
          device.suspend!(reason: 'plan_change_suspension')  # Uses updated suspend! method
          suspended_devices << {
            id: device.id,
            name: device.name
          }
        end

        {
          status: 'completed',
          subscription: subscription,
          suspended_devices: suspended_devices.count,
          suspension_summary: {
            suspended_count: suspended_devices.count,
            grace_period_days: 7,
            can_wake_immediately: true
          },
          message: "Plan changed with #{suspended_devices.count} devices suspended (can be woken anytime)"
        }
      end

      # ✅ UPDATED: Handle subscription changes with new scope
      def handle_subscription_change(user, old_plan, new_plan)
        return unless new_plan

        current_active_devices = user.devices.operational.count  # ✅ ENHANCED: Use operational count

        if new_plan.device_limit >= current_active_devices
          # Wake up suspended devices if there's room
          suspended_devices = user.devices.suspended.limit(new_plan.device_limit - current_active_devices)  # ✅ UPDATED: Use suspended scope
          suspended_devices.each(&:wake!)  # Uses updated wake! method
        else
          # Over limit - need to suspend excess devices
          Rails.logger.info "Device selection for downgrade should be handled by specific strategy methods"
        end
      end

      # ✅ FIXED: Updated parameter name to selected_device_ids
      def validate_device_selection(user, target_plan, selected_device_ids)
        if selected_device_ids.length > target_plan.device_limit
          raise ArgumentError, "Cannot select more than #{target_plan.device_limit} devices for #{target_plan.name} plan"
        end

        user_device_ids = user.devices.operational.pluck(:id)  # ✅ ENHANCED: Use operational devices
        invalid_ids = selected_device_ids - user_device_ids
        
        if invalid_ids.any?
          raise ArgumentError, "Invalid device IDs: #{invalid_ids.join(', ')}"
        end
      end

      def calculate_device_cost(subscription)
        return 0 if subscription.operational_devices_count < subscription.plan.device_limit  # ✅ ENHANCED

        Plan::ADDITIONAL_DEVICE_COST
      end
    end
  end
end