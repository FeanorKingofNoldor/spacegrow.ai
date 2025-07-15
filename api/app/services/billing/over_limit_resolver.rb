# app/services/billing/over_limit_resolver.rb
module Billing
  class OverLimitResolver < ApplicationService
    include ActiveModel::Model
    
    attr_reader :user, :context

    def initialize(user, context = {})
      @user = user
      @context = context
    end

    # ===== MAIN RESOLUTION FLOW =====
    
    def resolve_over_limit(excess_count, trigger_context = {})
      return failure('No over-limit situation to resolve') if excess_count <= 0
      
      {
        success: true,
        needs_resolution: true,
        excess_count: excess_count,
        trigger_context: trigger_context,
        resolution_options: build_resolution_options(excess_count),
        available_devices: devices_available_for_suspension,
        current_situation: current_situation_summary
      }
    end

    # ===== RESOLUTION EXECUTION =====
    
    def execute_resolution(strategy, options = {})
      case strategy
      when 'suspend_devices'
        execute_device_suspension(options[:device_ids])
      when 'buy_extra_slots'
        execute_slot_purchase(options[:slot_count])
      when 'upgrade_plan'
        execute_plan_upgrade(options[:plan_id])
      when 'hybrid'
        execute_hybrid_resolution(options)
      else
        failure("Unknown resolution strategy: #{strategy}")
      end
    end

    # ===== OPTION BUILDERS =====
    
    def build_resolution_options(excess_count)
      options = []
      
      # Option 1: Suspend devices (always available if devices exist)
      if devices_available_for_suspension.count >= excess_count
        options << {
          strategy: 'suspend_devices',
          title: "Suspend #{excess_count} device(s)",
          description: "Choose #{excess_count} device(s) to suspend (7-day grace period)",
          cost: 0,
          immediate: true,
          requires_selection: true,
          available_devices: devices_available_for_suspension
        }
      end
      
      # Option 2: Buy extra slots (always available)
      if user.subscription&.active?
        total_cost = excess_count * 5
        options << {
          strategy: 'buy_extra_slots',
          title: "Purchase #{excess_count} extra slot(s)",
          description: "Add #{excess_count} device slot(s) to your subscription",
          cost: total_cost,
          billing: "#{total_cost}/month ongoing",
          immediate: true,
          requires_selection: false
        }
      end
      
      # Option 3: Upgrade plan (if available)
      available_upgrades = available_plan_upgrades(excess_count)
      if available_upgrades.any?
        best_upgrade = available_upgrades.first
        cost_difference = calculate_plan_cost_difference(best_upgrade)
        
        options << {
          strategy: 'upgrade_plan',
          title: "Upgrade to #{best_upgrade.name}",
          description: "Get #{best_upgrade.device_limit} included device slots",
          cost: cost_difference,
          billing: "#{cost_difference > 0 ? '+' : ''}#{cost_difference}/month",
          immediate: true,
          requires_selection: false,
          plan: plan_summary(best_upgrade)
        }
      end
      
      # Option 4: Hybrid approach (for larger excesses)
      if excess_count > 2 && available_upgrades.any?
        options << build_hybrid_option(excess_count, available_upgrades.first)
      end
      
      options
    end

    private

    # ===== EXECUTION METHODS =====
    
    def execute_device_suspension(device_ids)
      return failure('Device IDs required for suspension') if device_ids.blank?
      
      device_manager = DeviceStateManager.new(user)
      result = device_manager.suspend_devices(device_ids, reason: 'over_limit_resolution')
      
      if result[:success]
        success(
          message: "Successfully suspended #{device_ids.count} device(s) to resolve over-limit situation",
          suspended_devices: result[:suspended_devices],
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      else
        failure("Failed to suspend devices: #{result[:error]}")
      end
    end

    def execute_slot_purchase(slot_count)
      return failure('Slot count must be positive') if slot_count <= 0
      
      results = []
      errors = []
      
      slot_count.times do
        slot_manager = ExtraSlotManager.new(user)
        result = slot_manager.purchase_slot
        
        if result[:success]
          results << result
        else
          errors << result[:error]
        end
      end
      
      if errors.empty?
        success(
          message: "Successfully purchased #{slot_count} extra device slot(s)",
          purchased_slots: results,
          total_monthly_cost: slot_count * 5,
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      else
        failure("Failed to purchase all slots: #{errors.join(', ')}")
      end
    end

    def execute_plan_upgrade(plan_id)
      # This would integrate with the plan change workflow
      # For now, return a placeholder
      {
        success: true,
        message: "Plan upgrade initiated",
        requires_plan_change_workflow: true,
        plan_id: plan_id
      }
    end

    def execute_hybrid_resolution(options)
      # Combine plan upgrade with device suspension or slot purchase
      # Implementation depends on specific hybrid strategy chosen
      {
        success: true,
        message: "Hybrid resolution initiated",
        requires_additional_workflow: true,
        options: options
      }
    end

    # ===== HELPER METHODS =====
    
    def devices_available_for_suspension
      user.devices.operational.map do |device|
        {
          id: device.id,
          name: device.name,
          device_type: device.device_type&.name,
          last_connection: device.last_connection,
          priority_score: calculate_suspension_priority(device)
        }
      end.sort_by { |d| d[:priority_score] }
    end

    def calculate_suspension_priority(device)
      # Lower score = higher priority for suspension
      # Prioritize devices that are offline or less recently used
      score = 0
      
      # Offline devices get higher suspension priority
      if device.last_connection.nil?
        score += 100  # Never connected
      elsif device.last_connection < 1.week.ago
        score += 50   # Offline for over a week
      elsif device.last_connection < 1.day.ago
        score += 20   # Offline for over a day
      end
      
      # Older devices get slightly higher suspension priority
      days_old = (Time.current - device.created_at) / 1.day
      score += [days_old / 10, 10].min  # Cap at 10 points for age
      
      score
    end

    def available_plan_upgrades(excess_count)
      return [] unless user.subscription
      
      current_plan = user.subscription.plan
      required_slots = DeviceSlotManager.new(user).used_slots
      
      Plan.where('device_limit >= ?', required_slots)
          .where('device_limit > ?', current_plan.device_limit)
          .order(:device_limit, :monthly_price)
    end

    def calculate_plan_cost_difference(target_plan)
      return 0 unless user.subscription
      
      current_cost = user.subscription.plan.monthly_price
      target_cost = target_plan.monthly_price
      
      target_cost - current_cost
    end

    def build_hybrid_option(excess_count, best_upgrade)
      # Example: Upgrade plan to cover most devices, buy 1-2 extra slots for remainder
      plan_slots = best_upgrade.device_limit
      current_plan_slots = user.subscription.plan.device_limit
      used_slots = DeviceSlotManager.new(user).used_slots
      
      slots_from_upgrade = plan_slots - current_plan_slots
      remaining_excess = excess_count - slots_from_upgrade
      
      if remaining_excess > 0 && remaining_excess <= 2
        plan_cost = calculate_plan_cost_difference(best_upgrade)
        slot_cost = remaining_excess * 5
        total_cost = plan_cost + slot_cost
        
        {
          strategy: 'hybrid',
          title: "Upgrade + #{remaining_excess} extra slot(s)",
          description: "Upgrade to #{best_upgrade.name} and add #{remaining_excess} extra slot(s)",
          cost: total_cost,
          billing: "#{total_cost}/month",
          immediate: true,
          requires_selection: false,
          details: {
            plan_upgrade: plan_summary(best_upgrade),
            extra_slots: remaining_excess,
            breakdown: {
              plan_cost_change: plan_cost,
              extra_slot_cost: slot_cost,
              total: total_cost
            }
          }
        }
      end
    end

    def current_situation_summary
      slot_manager = DeviceSlotManager.new(user)
      
      {
        current_slots: slot_manager.total_slots,
        used_slots: slot_manager.used_slots,
        available_slots: slot_manager.available_slots,
        over_limit_by: slot_manager.over_limit_count,
        plan_name: user.subscription&.plan&.name || 'No Plan',
        extra_slots: slot_manager.purchased_extra_slots
      }
    end

    def plan_summary(plan)
      {
        id: plan.id,
        name: plan.name,
        device_limit: plan.device_limit,
        monthly_price: plan.monthly_price,
        features: plan.features
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