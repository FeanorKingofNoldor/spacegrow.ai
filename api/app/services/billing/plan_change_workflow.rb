# app/services/billing/plan_change_workflow.rb
module Billing
  class PlanChangeWorkflow < ApplicationService
    include ActiveModel::Model
    
    attr_reader :user, :current_subscription

    def initialize(user)
      @user = user
      @current_subscription = user.subscription
    end

    # ===== PLAN CHANGE PREVIEW =====
    
    def preview_plan_change(target_plan, target_interval = 'month')
      return failure('User must have an active subscription') unless current_subscription&.active?
      return failure('Target plan not found') unless target_plan
      
      current_plan = current_subscription.plan
      slot_manager = DeviceSlotManager.new(user)
      
      # Determine change type
      change_type = determine_change_type(current_plan, target_plan)
      
      preview = {
        success: true,
        change_type: change_type,
        current_plan: plan_details(current_plan, current_subscription.interval),
        target_plan: plan_details(target_plan, target_interval),
        slot_impact: calculate_slot_impact(current_plan, target_plan, slot_manager),
        billing_impact: calculate_billing_impact(current_plan, target_plan, target_interval),
        required_actions: determine_required_actions(change_type, slot_manager, target_plan)
      }
      
      preview
    end

    # ===== PLAN CHANGE EXECUTION =====
    
    def execute_plan_change(target_plan, target_interval = 'month', options = {})
      preview = preview_plan_change(target_plan, target_interval)
      return preview unless preview[:success]
      
      case preview[:change_type]
      when 'upgrade'
        execute_upgrade(target_plan, target_interval)
      when 'downgrade_safe'
        execute_safe_downgrade(target_plan, target_interval)
      when 'downgrade_requires_action'
        execute_downgrade_with_action(target_plan, target_interval, options)
      when 'same_plan'
        execute_interval_change(target_plan, target_interval)
      else
        failure("Unknown change type: #{preview[:change_type]}")
      end
    end

    # ===== SPECIFIC EXECUTION METHODS =====
    
    def execute_upgrade(target_plan, target_interval)
      ActiveRecord::Base.transaction do
        old_plan = current_subscription.plan
        
        # Update subscription
        current_subscription.update!(
          plan: target_plan,
          interval: target_interval
        )
        
        # Wake up any suspended devices if we now have room
        wake_suspended_devices_if_possible
        
        # Update user role to match plan (if needed)
        update_user_role_for_plan(target_plan)
        
        success(
          message: "Successfully upgraded to #{target_plan.name} plan",
          subscription: subscription_summary,
          slot_usage: DeviceSlotManager.new(user).slot_summary,
          woken_devices: @woken_devices || []
        )
      end
    rescue => e
      Rails.logger.error "Plan upgrade failed: #{e.message}"
      failure("Failed to upgrade plan: #{e.message}")
    end

    def execute_safe_downgrade(target_plan, target_interval)
      ActiveRecord::Base.transaction do
        current_subscription.update!(
          plan: target_plan,
          interval: target_interval
        )
        
        update_user_role_for_plan(target_plan)
        
        success(
          message: "Successfully downgraded to #{target_plan.name} plan",
          subscription: subscription_summary,
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      end
    rescue => e
      Rails.logger.error "Plan downgrade failed: #{e.message}"
      failure("Failed to downgrade plan: #{e.message}")
    end

    def execute_downgrade_with_action(target_plan, target_interval, options)
      slot_manager = DeviceSlotManager.new(user)
      current_used = slot_manager.used_slots
      target_slots = target_plan.device_limit + slot_manager.purchased_extra_slots
      excess_count = current_used - target_slots
      
      return failure('No over-limit situation detected') if excess_count <= 0
      
      action = options[:action] || 'suspend_devices'
      
      case action
      when 'suspend_devices'
        execute_downgrade_with_suspension(target_plan, target_interval, options[:device_ids], excess_count)
      when 'buy_extra_slots'
        execute_downgrade_with_slot_purchase(target_plan, target_interval, excess_count)
      else
        failure("Unknown downgrade action: #{action}")
      end
    end

    def execute_interval_change(target_plan, target_interval)
      current_subscription.update!(interval: target_interval)
      
      success(
        message: "Successfully changed billing interval to #{target_interval}ly",
        subscription: subscription_summary
      )
    end

    private

    # ===== HELPER METHODS =====
    
    def determine_change_type(current_plan, target_plan)
      slot_manager = DeviceSlotManager.new(user)
      current_total_slots = current_plan.device_limit + slot_manager.purchased_extra_slots
      target_total_slots = target_plan.device_limit + slot_manager.purchased_extra_slots
      used_slots = slot_manager.used_slots
      
      if current_plan.id == target_plan.id
        'same_plan'
      elsif target_total_slots > current_total_slots
        'upgrade'
      elsif used_slots <= target_total_slots
        'downgrade_safe'
      else
        'downgrade_requires_action'
      end
    end

    def calculate_slot_impact(current_plan, target_plan, slot_manager)
      current_base = current_plan.device_limit
      target_base = target_plan.device_limit
      extra_slots = slot_manager.purchased_extra_slots
      used_slots = slot_manager.used_slots
      
      current_total = current_base + extra_slots
      target_total = target_base + extra_slots
      
      {
        current_base_slots: current_base,
        target_base_slots: target_base,
        extra_slots: extra_slots,
        current_total_slots: current_total,
        target_total_slots: target_total,
        used_slots: used_slots,
        slot_change: target_total - current_total,
        will_be_over_limit: used_slots > target_total,
        excess_devices: [used_slots - target_total, 0].max
      }
    end

    def calculate_billing_impact(current_plan, target_plan, target_interval)
      current_monthly = current_subscription.monthly_cost_with_granular_slots
      
      target_base_monthly = target_interval == 'month' ? 
                           target_plan.monthly_price : 
                           target_plan.yearly_price / 12
      
      target_monthly = target_base_monthly + (DeviceSlotManager.new(user).purchased_extra_slots * 5)
      
      {
        current_monthly_cost: current_monthly,
        target_monthly_cost: target_monthly,
        monthly_difference: target_monthly - current_monthly,
        current_interval: current_subscription.interval,
        target_interval: target_interval
      }
    end

    def determine_required_actions(change_type, slot_manager, target_plan)
      case change_type
      when 'upgrade', 'downgrade_safe', 'same_plan'
        []
      when 'downgrade_requires_action'
        excess = slot_manager.used_slots - (target_plan.device_limit + slot_manager.purchased_extra_slots)
        [
          {
            action: 'suspend_devices',
            description: "Choose #{excess} device(s) to suspend",
            required_count: excess
          },
          {
            action: 'buy_extra_slots',
            description: "Purchase #{excess} extra slot(s) (+$#{excess * 5}/month)",
            cost: excess * 5
          }
        ]
      else
        []
      end
    end

    def execute_downgrade_with_suspension(target_plan, target_interval, device_ids, excess_count)
      return failure('Device IDs required for suspension') if device_ids.blank?
      return failure("Must select exactly #{excess_count} devices") if device_ids.length != excess_count
      
      ActiveRecord::Base.transaction do
        # Suspend the selected devices
        device_manager = DeviceStateManager.new(user)
        suspension_result = device_manager.suspend_devices(device_ids, reason: 'plan_downgrade')
        
        return failure("Failed to suspend devices: #{suspension_result[:error]}") unless suspension_result[:success]
        
        # Execute the plan change
        current_subscription.update!(
          plan: target_plan,
          interval: target_interval
        )
        
        update_user_role_for_plan(target_plan)
        
        success(
          message: "Successfully downgraded to #{target_plan.name} and suspended #{excess_count} device(s)",
          subscription: subscription_summary,
          suspended_devices: suspension_result[:suspended_devices],
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      end
    rescue => e
      Rails.logger.error "Plan downgrade with suspension failed: #{e.message}"
      failure("Failed to downgrade plan: #{e.message}")
    end

    def execute_downgrade_with_slot_purchase(target_plan, target_interval, excess_count)
      ActiveRecord::Base.transaction do
        # Purchase the extra slots needed
        slot_manager = ExtraSlotManager.new(user)
        
        excess_count.times do
          result = slot_manager.purchase_slot
          return failure("Failed to purchase extra slot: #{result[:error]}") unless result[:success]
        end
        
        # Execute the plan change
        current_subscription.update!(
          plan: target_plan,
          interval: target_interval
        )
        
        update_user_role_for_plan(target_plan)
        
        success(
          message: "Successfully downgraded to #{target_plan.name} and purchased #{excess_count} extra slot(s)",
          subscription: subscription_summary,
          extra_slots_purchased: excess_count,
          extra_monthly_cost: excess_count * 5,
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      end
    rescue => e
      Rails.logger.error "Plan downgrade with slot purchase failed: #{e.message}"
      failure("Failed to downgrade plan: #{e.message}")
    end

    def wake_suspended_devices_if_possible
      slot_manager = DeviceSlotManager.new(user)
      available_slots = slot_manager.available_slots
      
      return if available_slots <= 0
      
      suspended_devices = user.devices.suspended.limit(available_slots)
      @woken_devices = []
      
      suspended_devices.each do |device|
        if device.wake!
          @woken_devices << {
            id: device.id,
            name: device.name,
            woken_reason: 'plan_upgrade_capacity'
          }
        end
      end
    end

    def update_user_role_for_plan(plan)
      # Sync user role with plan (following existing pattern)
      return if user.admin?
      
      new_role = plan.user_role
      
      if user.role != new_role
        Rails.logger.info "🔄 Updating user #{user.id} role from '#{user.role}' to '#{new_role}' (plan: #{plan.name})"
        user.update!(role: new_role)
      end
    end

    def plan_details(plan, interval)
      {
        id: plan.id,
        name: plan.name,
        device_limit: plan.device_limit,
        monthly_price: plan.monthly_price,
        yearly_price: plan.yearly_price,
        interval: interval,
        effective_monthly_cost: interval == 'month' ? plan.monthly_price : plan.yearly_price / 12
      }
    end

    def subscription_summary
      current_subscription.reload
      slot_manager = DeviceSlotManager.new(user)
      
      {
        id: current_subscription.id,
        plan: plan_details(current_subscription.plan, current_subscription.interval),
        status: current_subscription.status,
        interval: current_subscription.interval,
        device_limit: slot_manager.total_slots,
        extra_slots: slot_manager.purchased_extra_slots,
        monthly_cost: current_subscription.monthly_cost_with_granular_slots
      }
    end

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message)
      { success: false, error: message }
    end
  end
end