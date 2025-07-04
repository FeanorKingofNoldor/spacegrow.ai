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

  # ✅ ENHANCED: Device management endpoint for hibernation dashboard
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
        # ✅ ADDED: Additional hibernation data
        operational_devices: operational_devices.map { |d| device_json(d) },
        hibernating_devices: hibernating_devices.map { |d| hibernating_device_json(d) },
        hibernation_priorities: @subscription.hibernation_priorities,
        upsell_options: @subscription.generate_upsell_options,
        over_device_limit: @subscription.operational_devices_count > @subscription.device_limit
      }
    }
  end

  # ✅ NEW: Activate device endpoint (for ESP32 or manual activation)
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

    # Use the subscription's activation logic
    result = @subscription.activate_device!(device)
    
    render json: {
      status: 'success',
      data: result,
      message: result[:message]
    }
  end

  # ✅ ENHANCED: Wake up hibernating devices
  def wake_devices
    device_ids = params[:device_ids] || []
    result = @subscription.wake_up_devices!(device_ids)
    
    if result[:success]
      render json: {
        status: 'success',
        message: "Successfully woke up #{result[:woken_devices].count} device(s)",
        data: {
          woken_devices: result[:woken_devices],
          # ✅ ADDED: Additional data from both versions
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

  # ✅ ENHANCED: Hibernate operational devices
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
          # ✅ ADDED: Additional data from both versions
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
        current_plan: plan_json(current_subscription.plan),
        target_plan: plan_json(target_plan),
        analysis: analysis
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Plan not found'
    }, status: :not_found
  end

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

    case strategy
    when 'immediate'
      result = execute_immediate_plan_change(current_subscription, target_plan, target_interval)
    when 'immediate_with_device_selection'
      selected_devices = params[:selected_devices] || []
      result = execute_plan_change_with_device_selection(current_subscription, target_plan, target_interval, selected_devices)
    when 'pay_for_extra_devices'
      result = execute_plan_change_with_extra_devices(current_subscription, target_plan, target_interval)
    else
      return render json: {
        status: 'error',
        message: 'Invalid strategy'
      }, status: :bad_request
    end

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
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Plan not found'
    }, status: :not_found
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
      
      # ✅ NEW: Hibernation-aware device counts
      device_counts: {
        total: subscription.total_devices_count,
        operational: subscription.operational_devices_count,
        hibernating: subscription.hibernating_devices_count
      }
    }
  end

  # ✅ ENHANCED: Device JSON with hibernation info (supports both formats)
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

  # ✅ NEW: Enhanced device JSON for hibernation (specific format for hibernating devices)
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

  # ✅ ENHANCED: Use operational devices for plan analysis (hibernation-aware)
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
    
    # ✅ ENHANCED: Count operational devices (not hibernating ones)
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
        available_strategies: ['immediate_with_device_selection', 'pay_for_extra_devices'],
        description: "Downgrade requires action - #{excess_devices} operational devices exceed new limit",
        excess_devices: excess_devices,
        current_device_count: current_operational_devices,
        new_device_limit: target_plan.device_limit
      }
    end
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

  def execute_plan_change_with_device_selection(subscription, target_plan, target_interval, selected_devices)
    device_ids = selected_devices.is_a?(Array) ? selected_devices : []
    
    if device_ids.length > target_plan.device_limit
      return { success: false, error: "Too many devices selected for #{target_plan.name} plan" }
    end
    
    ActiveRecord::Base.transaction do
      # ✅ ENHANCED: Hibernate operational devices not in selection
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
    # ✅ ENHANCED: Count operational devices for extra slot calculation
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