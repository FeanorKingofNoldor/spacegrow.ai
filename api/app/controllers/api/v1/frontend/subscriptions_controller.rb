# app/controllers/api/v1/frontend/subscriptions_controller.rb - REFACTORED
class Api::V1::Frontend::SubscriptionsController < Api::V1::Frontend::ProtectedController
  include ApiResponseHandling
  include SubscriptionJsonHandling
  
  before_action :set_subscription, only: [:cancel, :add_device_slot, :remove_device_slot, :device_management, :wake_devices, :suspend_devices, :activate_device]

  def index
    plans = Plan.all.order(:monthly_price)
    current_subscription = current_user.subscription
    
    render_success({
      plans: plans.map { |plan| plan_json(plan) },
      current_subscription: current_subscription ? subscription_json(current_subscription) : nil
    })
  end

  def device_management
    # Use new DeviceSlotManager and DeviceStateManager
    slot_manager = Billing::DeviceSlotManager.new(current_user)
    state_manager = Billing::DeviceStateManager.new(current_user)
    
    render_success({
      slot_usage: slot_manager.slot_summary,
      device_states: state_manager.device_states_summary,
      devices_by_state: state_manager.devices_by_state,
      available_for_suspension: state_manager.devices_available_for_suspension,
      available_for_waking: state_manager.devices_available_for_waking
    })
  end

def activate_device
  device_id = params[:device_id]
  return render_error('Device ID is required', [], 400) unless device_id
  
  device = current_user.devices.find_by(id: device_id)
  return render_error('Device not found', [], 404) unless device
  
  state_manager = Billing::DeviceStateManager.new(current_user)
  result = state_manager.activate_device(device)
  
  if result[:success]
    render_success(result, result[:message])
  else
    if result[:over_limit]
      render_error(result[:message], [], 422)
    else
      render_error(result[:error])
    end
  end
end

  def wake_devices
    device_ids = params[:device_ids] || []
    
    state_manager = Billing::DeviceStateManager.new(current_user)
    result = state_manager.wake_devices(device_ids)
    
    if result[:success]
      render_success(result, result[:message])
    else
      render_error(result[:error])
    end
  end

  def suspend_devices
    device_ids = params[:device_ids] || []
    reason = params[:reason] || 'User choice'
    
    state_manager = Billing::DeviceStateManager.new(current_user)
    result = state_manager.suspend_devices(device_ids, reason: reason)
    
    if result[:success]
      render_success(result, result[:message])
    else
      render_error(result[:error])
    end
  end

def preview_change
  target_plan = Plan.find(params[:plan_id])
  target_interval = params[:interval] || 'month'
  
  workflow = Billing::PlanChangeWorkflow.new(current_user)
  result = workflow.preview_plan_change(target_plan, target_interval)
  
  if result[:success]
    render_success(result)
  else
    render_error(result[:error])
  end
rescue ActiveRecord::RecordNotFound
  render_error('Plan not found', [], 404)
end

def change_plan
  target_plan = Plan.find(params[:plan_id])
  target_interval = params[:interval] || 'month'
  options = {
    device_ids: params[:selected_device_ids] || [],
    action: params[:action] || 'immediate'
  }
  
  workflow = Billing::PlanChangeWorkflow.new(current_user)
  result = workflow.execute_plan_change(target_plan, target_interval, options)
  
  if result[:success]
    render_success({
      change_result: result,
      updated_subscription: subscription_json(current_user.subscription.reload),
      slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
    }, result[:message])
  else
    render_error(result[:error])
  end
rescue ActiveRecord::RecordNotFound
  render_error('Plan not found', [], 404)
rescue ArgumentError, StandardError => e
  render_error(e.message)
end

def select_plan
  plan = Plan.find(params[:plan_id])
  interval = params[:interval] || 'month'

  if current_user.subscription&.active?
    # Use new PlanChangeWorkflow for existing subscribers
    workflow = Billing::PlanChangeWorkflow.new(current_user)
    result = workflow.execute_plan_change(plan, interval)
    
    if result[:success]
      render_success({
        subscription: subscription_json(current_user.subscription.reload),
        slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
      }, result[:message])
    else
      render_error(result[:error])
    end
  else
    # Keep existing SubscriptionManagement::SubscriptionManagement::SubscriptionService for new subscriptions (it works fine)
    subscription = SubscriptionManagement::SubscriptionManagement::SubscriptionManagement::SubscriptionService.create_subscription(
      user: current_user,
      plan: plan,
      interval: interval
    )

    if subscription.persisted?
      render_success({
        subscription: subscription_json(subscription),
        slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
      }, "Welcome to SpaceGrow! Your #{plan.name} plan is now active.")
    else
      render_error("Couldn't activate your plan. Please try again.", subscription.errors.full_messages)
    end
  end
rescue ActiveRecord::RecordNotFound
  render_error('Plan not found', [], 404)
rescue ArgumentError, StandardError => e
  render_error(e.message)
end

  def cancel
    SubscriptionManagement::SubscriptionManagement::SubscriptionManagement::SubscriptionService.cancel_subscription(@subscription)
    render_success(nil, 'Subscription canceled successfully')
  end

def add_device_slot
  extra_slot_manager = Billing::ExtraSlotManager.new(current_user)
  result = extra_slot_manager.purchase_slot
  
  if result[:success]
    render_success({
      slot: result[:slot],
      new_total_slots: result[:new_total_slots],
      monthly_cost_increase: result[:monthly_cost_increase],
      updated_slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
    }, result[:message])
  else
    render_error(result[:error])
  end
end

def remove_device_slot
  # For now, redirect to the new cancel_extra_slot endpoint
  # This maintains backward compatibility
  extra_slot_manager = Billing::ExtraSlotManager.new(current_user)
  slots = extra_slot_manager.list_user_slots
  
  if slots.any?
    # Cancel the most recent slot
    latest_slot = slots.last
    result = extra_slot_manager.cancel_slot(latest_slot[:id])
    
    if result[:success]
      render_success({
        cancelled_slot: result[:slot],
        updated_slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
      }, result[:message])
    else
      render_error(result[:error])
    end
  else
    render_error('No extra device slots to remove')
  end
end

  def slot_overview
  slot_manager = Billing::DeviceSlotManager.new(current_user)
  extra_slot_manager = Billing::ExtraSlotManager.new(current_user)
  
  render_success({
    slot_summary: slot_manager.slot_summary,
    slot_breakdown: slot_manager.slots_breakdown,
    extra_slots: extra_slot_manager.list_user_slots,
    purchase_info: extra_slot_manager.slot_purchase_info
  })
  end

def purchase_extra_slot
  extra_slot_manager = Billing::ExtraSlotManager.new(current_user)
  result = extra_slot_manager.purchase_slot
  
  if result[:success]
    render_success({
      slot: result[:slot],
      new_total_slots: result[:new_total_slots],
      monthly_cost_increase: result[:monthly_cost_increase],
      updated_slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
    }, result[:message])
  else
    render_error(result[:error])
  end
end

def cancel_extra_slot
  slot_id = params[:slot_id]
  return render_error('Slot ID is required', [], 400) unless slot_id
  
  extra_slot_manager = Billing::ExtraSlotManager.new(current_user)
  result = extra_slot_manager.cancel_slot(slot_id)
  
  if result[:success]
    render_success({
      cancelled_slot: result[:slot],
      new_total_slots: result[:new_total_slots],
      monthly_cost_decrease: result[:monthly_cost_decrease],
      updated_slot_usage: Billing::DeviceSlotManager.new(current_user).slot_summary
    }, result[:message])
  elsif result[:needs_device_selection]
    render_error(result[:message], result[:available_actions], 422)
  else
    render_error(result[:error])
  end
end

  private

  def set_subscription
    @subscription = current_user.subscription
    render_error('No subscription found', [], 404) unless @subscription
  end
end