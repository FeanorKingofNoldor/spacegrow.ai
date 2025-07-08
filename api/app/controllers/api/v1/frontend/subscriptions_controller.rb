# app/controllers/api/v1/frontend/subscriptions_controller.rb
class Api::V1::Frontend::SubscriptionsController < Api::V1::Frontend::ProtectedController
  before_action :set_subscription, only: [:cancel, :add_device_slot, :remove_device_slot, :device_management, :wake_devices, :hibernate_devices, :activate_device]

  def index
    plans = Plan.all.order(:monthly_price)
    current_subscription = current_user.subscription
    
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) },
        current_subscription: current_subscription ? subscription_json(current_subscription) : nil
      }
    }
  end

  def device_management
    operational_devices = current_user.devices.operational.includes(:device_type)
    hibernating_devices = current_user.devices.hibernating.includes(:device_type)
    
    render json: {
      status: 'success',
      data: {
        subscription: subscription_json(@subscription),
        device_limits: {
          total_limit: @subscription.device_limit,
          operational_count: @subscription.operational_devices_count,
          hibernating_count: @subscription.hibernating_devices_count,
          available_slots: [@subscription.device_limit - @subscription.operational_devices_count, 0].max
        },
        devices: {
          operational: operational_devices.map { |d| device_json(d) },
          hibernating: hibernating_devices.map { |d| device_json(d, include_hibernation: true) }
        },
        operational_devices: operational_devices.map { |d| device_json(d) },
        hibernating_devices: hibernating_devices.map { |d| hibernating_device_json(d) },
        hibernation_priorities: @subscription.hibernation_priorities,
        upsell_options: @subscription.generate_upsell_options,
        over_device_limit: @subscription.operational_devices_count > @subscription.device_limit
      }
    }
  end

  def activate_device
    device_id = params[:device_id]
    device = current_user.devices.find_by(id: device_id)
    
    unless device
      return render json: {
        status: 'error',
        message: 'Device not found'
      }, status: :not_found
    end

    unless @subscription&.active?
      return render json: {
        status: 'error',
        message: 'No active subscription found'
      }, status: :unprocessable_entity
    end

    result = @subscription.activate_device!(device)
    
    render json: {
      status: 'success',
      data: result,
      message: result[:message]
    }
  end

  def wake_devices
    device_ids = params[:device_ids] || []
    result = @subscription.wake_up_devices!(device_ids)
    
    if result[:success]
      render json: {
        status: 'success',
        message: "Successfully woke up #{result[:woken_devices].count} device(s)",
        data: {
          woken_devices: result[:woken_devices],
          operational_count: @subscription.operational_devices_count,
          available_slots: [@subscription.device_limit - @subscription.operational_devices_count, 0].max
        }
      }
    else
      render json: {
        status: 'error',
        message: result[:error]
      }, status: :unprocessable_entity
    end
  end

  def hibernate_devices
    device_ids = params[:device_ids] || []
    reason = params[:reason] || 'user_choice'
    result = @subscription.hibernate_devices!(device_ids, reason: reason)
    
    if result[:success]
      render json: {
        status: 'success',
        message: "Successfully hibernated #{result[:hibernated_devices].count} device(s)",
        data: {
          hibernated_devices: result[:hibernated_devices],
          operational_count: @subscription.operational_devices_count,
          hibernating_count: @subscription.hibernating_devices_count
        }
      }
    else
      render json: {
        status: 'error',
        message: result[:error]
      }, status: :unprocessable_entity
    end
  end

  def preview_change
    target_plan = Plan.find(params[:plan_id])
    target_interval = params[:interval] || 'month'
    current_subscription = current_user.subscription

    unless current_subscription
      return render json: {
        status: 'error',
        message: 'No active subscription found'
      }, status: :unprocessable_entity
    end

    analysis = analyze_plan_change(current_subscription, target_plan, target_interval)
    
    render json: {
      status: 'success',
      data: {
        change_type: analysis[:change_type],
        current_plan: {
          **plan_json(current_subscription.plan),
          devices_used: current_subscription.operational_devices_count,
          device_limit: current_subscription.plan.device_limit,
          current_interval: current_subscription.interval
        },
        target_plan: {
          **plan_json(target_plan),
          target_interval: target_interval
        },
        device_impact: build_device_impact(analysis, current_subscription, target_plan),
        billing_impact: build_billing_impact(current_subscription, target_plan, target_interval),
        available_strategies: build_strategies(analysis, current_subscription, target_plan),
        warnings: build_warnings(analysis, current_subscription, target_plan)
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Plan not found'
    }, status: :not_found
  end

  # ✅ FIXED: Updated change_plan method with corrected strategy names and parameter handling
  def change_plan
    target_plan = Plan.find(params[:plan_id])
    target_interval = params[:interval] || 'month'
    strategy = params[:strategy] || 'immediate'
    current_subscription = current_user.subscription

    unless current_subscription
      return render json: {
        status: 'error',
        message: 'No active subscription found'
      }, status: :unprocessable_entity
    end

    # ✅ FIXED: Updated strategy handling to match frontend names
    case strategy
    when 'immediate'
      result = execute_immediate_plan_change(current_subscription, target_plan, target_interval)
    when 'immediate_with_selection'  # ✅ FIXED: Changed from 'immediate_with_device_selection'
      selected_device_ids = params[:selected_device_ids] || []  # ✅ FIXED: Changed from selected_devices
      result = execute_plan_change_with_device_selection(current_subscription, target_plan, target_interval, selected_device_ids)
    when 'pay_for_extra'  # ✅ FIXED: Changed from 'pay_for_extra_devices'
      result = execute_plan_change_with_extra_devices(current_subscription, target_plan, target_interval)
    when 'hibernate_excess'  # ✅ NEW: Added missing strategy
      selected_device_ids = params[:selected_device_ids] || []
      result = execute_plan_change_with_hibernation(current_subscription, target_plan, target_interval, selected_device_ids)
    when 'end_of_period'  # ✅ NEW: Added missing strategy
      selected_device_ids = params[:selected_device_ids] || []
      result = schedule_plan_change_for_period_end(current_subscription, target_plan, target_interval, selected_device_ids)
    else
      return render json: {
        status: 'error',
        message: "Invalid strategy: #{strategy}"  # ✅ IMPROVED: Show which strategy was invalid
      }, status: :bad_request
    end

    if result[:success]
      render json: {
        status: 'success',
        message: result[:message],
        data: {
          change_result: result,
          updated_subscription: subscription_json(current_user.subscription.reload)
        }
      }
    else
      render json: {
        status: 'error',
        message: result[:error]
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Plan not found'
    }, status: :not_found
  end

  # ✅ NEW: Added missing devices_for_selection endpoint
  def devices_for_selection
    devices = DeviceManagementService.get_devices_for_selection(current_user)
    
    recommendations = {
      recommended_to_disable: devices.count { |d| d[:recommendation] == 'recommended_to_disable' },
      consider_disabling: devices.count { |d| d[:recommendation] == 'consider_disabling' },
      keep_active: devices.count { |d| d[:recommendation] == 'keep_active' }
    }
    
    render json: {
      status: 'success',
      data: {
        devices: devices,
        total_count: devices.count,
        recommendations: recommendations
      }
    }
  end

  def schedule_change
    target_plan = Plan.find(params[:plan_id])
    target_interval = params[:interval] || 'month'
    effective_date = params[:effective_date] || 'end_of_period'
    current_subscription = current_user.subscription

    unless current_subscription
      return render json: {
        status: 'error',
        message: 'No active subscription found'
      }, status: :unprocessable_entity
    end
    
    scheduled_change = ScheduledPlanChange.create!(
      subscription: current_subscription,
      target_plan: target_plan,
      target_interval: target_interval,
      scheduled_for: calculate_effective_date(effective_date, current_subscription),
      status: 'pending',
      notes: "Plan change from #{current_subscription.plan.name} to #{target_plan.name}"
    )
    
    render json: {
      status: 'success',
      message: 'Plan change scheduled successfully',
      data: {
        scheduled_change: {
          id: scheduled_change.id,
          target_plan: plan_json(target_plan),
          scheduled_for: scheduled_change.scheduled_for,
          status: scheduled_change.status
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Plan not found'
    }, status: :not_found
  rescue StandardError => e
    render json: {
      status: 'error',
      message: e.message
    }, status: :unprocessable_entity
  end

  def select_plan
    plan = Plan.find(params[:plan_id])
    interval = params[:interval] || 'month'

    if current_user.subscription&.active?
      result = execute_immediate_plan_change(current_user.subscription, plan, interval)
      
      if result[:success]
        render json: {
          status: 'success',
          message: result[:message],
          data: {
            subscription: subscription_json(current_user.subscription.reload)
          }
        }
      else
        render json: {
          status: 'error',
          message: result[:error]
        }, status: :unprocessable_entity
      end
    else
      subscription = SubscriptionService.create_subscription(
        user: current_user,
        plan: plan,
        interval: interval
      )

      if subscription.persisted?
        message = "Welcome to XSpaceGrow! Your #{plan.name} plan is now active."
        
        render json: {
          status: 'success',
          message: message,
          data: {
            subscription: subscription_json(subscription)
          }
        }
      else
        render json: {
          status: 'error',
          message: "Couldn't activate your plan. Please try again.",
          errors: subscription.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Plan not found'
    }, status: :not_found
  end

  def cancel
    SubscriptionService.cancel_subscription(@subscription)
    render json: {
      status: 'success',
      message: 'Subscription canceled successfully'
    }
  end

  def add_device_slot
    if @subscription&.active?
      @subscription.increment!(:additional_device_slots)
      render json: {
        status: 'success',
        message: 'Successfully added an additional device slot.',
        data: {
          additional_device_slots: @subscription.additional_device_slots,
          device_limit: @subscription.device_limit
        }
      }
    else
      render json: {
        status: 'error',
        message: "You don't have an active subscription to modify."
      }, status: :unprocessable_entity
    end
  end

  def remove_device_slot
    device_id = params[:device_id]
    
    unless device_id
      return render json: {
        status: 'error',
        message: 'Device ID is required'
      }, status: :bad_request
    end

    message = @subscription.remove_specific_device(device_id)

    render json: {
      status: 'success',
      message: message
    }
  rescue StandardError => e
    render json: {
      status: 'error',
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def set_subscription
    @subscription = current_user.subscription
    
    unless @subscription
      render json: {
        status: 'error',
        message: 'No subscription found'
      }, status: :not_found
    end
  end

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
        hibernating: subscription.hibernating_devices_count
      }
    }
  end

  def device_json(device, include_hibernation: false)
    json = {
      id: device.id,
      name: device.name,
      device_type: device.device_type.name,
      status: device.status,
      alert_status: device.alert_status,
      last_connection: device.last_connection,
      operational: device.operational?,
      hibernating: device.hibernating?,
      hibernation_priority_score: device.hibernation_priority_score,
      created_at: device.created_at
    }
    
    if include_hibernation
      json.merge!({
        hibernated_at: device.hibernated_at,
        hibernated_reason: device.hibernated_reason,
        in_grace_period: device.in_grace_period?,
        grace_period_ends_at: device.grace_period_ends_at
      })
    end
    
    json
  end

  def hibernating_device_json(device)
    {
      device_id: device.id,
      name: device.name,
      device_type: device.device_type.name,
      hibernated_at: device.hibernated_at,
      hibernated_reason: device.hibernated_reason,
      in_grace_period: device.in_grace_period?,
      grace_period_ends_at: device.grace_period_ends_at,
      hibernation_priority_score: device.hibernation_priority_score,
      last_connection: device.last_connection,
      created_at: device.created_at
    }
  end

  def analyze_plan_change(current_subscription, target_plan, target_interval)
    current_plan = current_subscription.plan
    
    if current_plan.id == target_plan.id && current_subscription.interval == target_interval
      return {
        change_type: 'current',
        available_strategies: ['none'],
        description: 'No changes needed - already on this plan and interval'
      }
    end
    
    if current_plan.id == target_plan.id && current_subscription.interval != target_interval
      return {
        change_type: 'interval_change',
        available_strategies: ['immediate'],
        description: "Change billing from #{current_subscription.interval}ly to #{target_interval}ly"
      }
    end
    
    if target_plan.device_limit > current_plan.device_limit
      return {
        change_type: 'upgrade',
        available_strategies: ['immediate'],
        description: "Upgrade from #{current_plan.name} to #{target_plan.name}",
        device_change: target_plan.device_limit - current_plan.device_limit
      }
    end
    
    current_operational_devices = current_subscription.operational_devices_count
    
    if current_operational_devices <= target_plan.device_limit
      return {
        change_type: 'downgrade_safe',
        available_strategies: ['immediate'],
        description: "Safe downgrade - current operational devices (#{current_operational_devices}) within new limit (#{target_plan.device_limit})"
      }
    else
      excess_devices = current_operational_devices - target_plan.device_limit
      return {
        change_type: 'downgrade_warning',
        available_strategies: ['immediate_with_selection', 'pay_for_extra', 'hibernate_excess', 'end_of_period'],
        description: "Downgrade requires action - #{excess_devices} operational devices exceed new limit",
        excess_devices: excess_devices,
        current_device_count: current_operational_devices,
        new_device_limit: target_plan.device_limit
      }
    end
  end

  def build_device_impact(analysis, current_subscription, target_plan)
    current_operational_devices = current_subscription.operational_devices_count
    target_device_limit = target_plan.device_limit
    
    requires_device_selection = analysis[:change_type] == 'downgrade_warning'
    excess_devices = [current_operational_devices - target_device_limit, 0].max
    
    affected_devices = []
    if requires_device_selection
      affected_devices = current_user.devices.operational.map do |device|
        {
          id: device.id,
          name: device.name
        }
      end
    end

    {
      requires_device_selection: requires_device_selection,
      current_device_count: current_operational_devices,
      target_device_limit: target_device_limit,
      device_difference: target_device_limit - current_subscription.plan.device_limit,
      excess_device_count: excess_devices,
      affected_devices: affected_devices
    }
  end

  def build_billing_impact(current_subscription, target_plan, target_interval)
    current_monthly_cost = current_subscription.plan.monthly_price + 
                          (current_subscription.additional_device_slots * 5)
    
    target_monthly_cost = if target_interval == 'month'
                           target_plan.monthly_price
                         else
                           (target_plan.yearly_price / 12.0).round(2)
                         end
    
    cost_difference = target_monthly_cost - current_monthly_cost
    
    {
      current_monthly_cost: current_monthly_cost,
      target_monthly_cost: target_monthly_cost,
      cost_difference: cost_difference,
      no_refund_policy: true,
      extra_device_cost_per_month: 5.0,
      potential_extra_cost: [current_subscription.operational_devices_count - target_plan.device_limit, 0].max * 5
    }
  end

  def build_strategies(analysis, current_subscription, target_plan)
    strategies = []
    
    case analysis[:change_type]
    when 'current'
      strategies << {
        type: 'none',
        name: 'No Change Needed',
        description: 'You are already on this plan and billing interval',
        recommended: true
      }
    
    when 'upgrade', 'interval_change'
      strategies << {
        type: 'immediate',
        name: 'Change Immediately',
        description: 'Your plan will be updated right away and billed on your next cycle',
        recommended: true
      }
    
    when 'downgrade_safe'
      strategies << {
        type: 'immediate',
        name: 'Change Immediately',
        description: 'Safe to change now - all your devices will remain active',
        recommended: true
      }
      
      strategies << {
        type: 'end_of_period',
        name: 'Change at End of Period',
        description: 'Wait until your current billing period ends',
        recommended: false
      }
    
    when 'downgrade_warning'
      excess_devices = analysis[:excess_devices] || 0
      
      strategies << {
        type: 'immediate_with_selection',
        name: 'Choose Devices to Keep',
        description: "Select which #{target_plan.device_limit} devices to keep active",
        recommended: true
      }
      
      strategies << {
        type: 'hibernate_excess',
        name: 'Hibernate Extra Devices',
        description: "Hibernate #{excess_devices} devices (can wake them later)",
        recommended: false,
        devices_to_hibernate: excess_devices
      }
      
      strategies << {
        type: 'pay_for_extra',
        name: 'Pay for Extra Devices',
        description: "Keep all devices active (+$#{excess_devices * 5}/month)",
        recommended: false,
        extra_monthly_cost: excess_devices * 5
      }
      
      strategies << {
        type: 'end_of_period',
        name: 'Schedule for Later',
        description: 'Schedule the change for the end of your billing period',
        recommended: false
      }
    end
    
    strategies
  end

  def build_warnings(analysis, current_subscription, target_plan)
    warnings = []
    
    case analysis[:change_type]
    when 'downgrade_warning'
      excess_count = analysis[:excess_devices] || 0
      warnings << "You have #{excess_count} more operational devices than the #{target_plan.name} plan allows"
      warnings << "Excess devices will need to be hibernated or you'll pay extra fees"
    
    when 'downgrade_safe'
      warnings << "This is a downgrade but all your devices will remain active"
    
    when 'upgrade'
      if target_plan.monthly_price > current_subscription.plan.monthly_price
        increase = target_plan.monthly_price - current_subscription.plan.monthly_price
        warnings << "Your monthly cost will increase by $#{increase}"
      end
    end
    
    warnings << "No refunds will be issued for the current billing period"
    
    if current_subscription.additional_device_slots > 0
      warnings << "Your additional device slots will be reset"
    end
    
    warnings
  end

  def execute_immediate_plan_change(subscription, target_plan, target_interval)
    subscription.update!(
      plan: target_plan,
      interval: target_interval
    )
    
    { success: true, message: "Plan changed to #{target_plan.name} (#{target_interval}ly)" }
  rescue => e
    { success: false, error: e.message }
  end

  # ✅ FIXED: Updated to use selected_device_ids parameter
  def execute_plan_change_with_device_selection(subscription, target_plan, target_interval, selected_device_ids)
    device_ids = selected_device_ids.is_a?(Array) ? selected_device_ids : []
    
    if device_ids.length > target_plan.device_limit
      return { success: false, error: "Too many devices selected for #{target_plan.name} plan" }
    end
    
    ActiveRecord::Base.transaction do
      excess_devices = current_user.devices.operational.where.not(id: device_ids)
      excess_devices.each { |device| device.hibernate!(reason: 'plan_change') }
      
      subscription.update!(
        plan: target_plan,
        interval: target_interval,
        additional_device_slots: 0
      )
    end
    
    { success: true, message: "Plan changed with #{excess_devices.count} devices hibernated" }
  rescue => e
    { success: false, error: e.message }
  end

  def execute_plan_change_with_extra_devices(subscription, target_plan, target_interval)
    current_operational_devices = subscription.operational_devices_count
    extra_slots_needed = current_operational_devices - target_plan.device_limit
    
    subscription.update!(
      plan: target_plan,
      interval: target_interval,
      additional_device_slots: extra_slots_needed
    )
    
    { success: true, message: "Plan changed with #{extra_slots_needed} additional device slots" }
  rescue => e
    { success: false, error: e.message }
  end

  # ✅ NEW: Added hibernate_excess strategy handler
  def execute_plan_change_with_hibernation(subscription, target_plan, target_interval, selected_device_ids)
    device_ids = selected_device_ids.is_a?(Array) ? selected_device_ids : []
    
    ActiveRecord::Base.transaction do
      # Hibernate the selected excess devices
      devices_to_hibernate = current_user.devices.operational.where(id: device_ids)
      devices_to_hibernate.each { |device| device.hibernate!(reason: 'plan_change_hibernation') }
      
      subscription.update!(
        plan: target_plan,
        interval: target_interval,
        additional_device_slots: 0
      )
    end
    
    { 
      success: true, 
      message: "Plan changed with #{device_ids.length} devices hibernated",
      hibernated_devices: device_ids.length,
      hibernation_summary: {
        hibernated_count: device_ids.length,
        grace_period_days: 7,
        can_wake_immediately: true
      }
    }
  rescue => e
    { success: false, error: e.message }
  end

  # ✅ NEW: Added end_of_period strategy handler
  def schedule_plan_change_for_period_end(subscription, target_plan, target_interval, selected_device_ids)
    effective_date = subscription.current_period_end
    
    # Create scheduled plan change
    scheduled_change = ScheduledPlanChange.create!(
      subscription: subscription,
      target_plan: target_plan,
      target_interval: target_interval,
      scheduled_for: effective_date,
      status: 'pending',
      notes: "Plan change with device hibernation scheduled for period end"
    )
    
    # If devices need to be hibernated, schedule that too
    if selected_device_ids.present?
      DeviceManagementService.schedule_device_changes(
        current_user, 
        selected_device_ids, 
        effective_date
      )
    end
    
    # Schedule the job
    ScheduledPlanChangeJob.set(wait_until: effective_date)
                         .perform_later(subscription.id, target_plan.id, target_interval)
    
    { 
      success: true, 
      message: "Plan change scheduled for #{effective_date.strftime('%B %d, %Y')}",
      status: 'scheduled',
      effective_date: effective_date,
      scheduled_change_id: scheduled_change.id
    }
  rescue => e
    { success: false, error: e.message }
  end

  def calculate_effective_date(effective_date, subscription)
    case effective_date
    when 'end_of_period'
      subscription.current_period_end
    when 'immediate'
      Time.current
    else
      Time.parse(effective_date)
    end
  rescue
    subscription.current_period_end
  end
end