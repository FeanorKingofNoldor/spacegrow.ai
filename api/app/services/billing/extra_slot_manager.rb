# app/services/billing/extra_slot_manager.rb
module Billing
  class ExtraSlotManager < ApplicationService
    include ActiveModel::Model
    
    attr_reader :user, :subscription

    def initialize(user)
      @user = user
      @subscription = user.subscription
    end

    # ===== SLOT PURCHASE =====

    def purchase_slot
      return failure('User must have an active subscription to purchase extra slots') unless subscription&.active?
      
      ActiveRecord::Base.transaction do
        slot = subscription.extra_device_slots.create!(
          monthly_cost: 5.00,
          status: 'active',
          activated_at: Time.current
        )
        
        # TODO: Add Stripe subscription item for billing
        # create_stripe_subscription_item(slot)
        
        success(
          message: 'Extra device slot purchased successfully',
          slot: slot,
          new_total_slots: slot_manager.total_slots,
          monthly_cost_increase: 5.00
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      failure("Failed to purchase slot: #{e.message}")
    rescue => e
      Rails.logger.error "ExtraSlotManager purchase error: #{e.message}"
      failure('An error occurred while purchasing the slot')
    end

    # ===== SLOT CANCELLATION =====

    def cancel_slot(slot_id)
      slot = find_user_slot(slot_id)
      return failure('Slot not found or not owned by user') unless slot
      return failure('Slot is already cancelled') if slot.cancelled?
      
      # Check if cancelling this slot would put user over limit
      over_limit_check = check_over_limit_after_cancellation
      
      if over_limit_check[:would_be_over_limit]
        return over_limit_response(over_limit_check)
      end
      
      # Safe to cancel
      execute_slot_cancellation(slot)
    end

    def cancel_slot_with_device_selection(slot_id, devices_to_suspend: [])
      slot = find_user_slot(slot_id)
      return failure('Slot not found or not owned by user') unless slot
      return failure('Slot is already cancelled') if slot.cancelled?
      
      over_limit_check = check_over_limit_after_cancellation
      return failure('No devices need to be suspended') unless over_limit_check[:would_be_over_limit]
      
      # Validate device selection
      validation = validate_device_selection(devices_to_suspend, over_limit_check[:excess_count])
      return validation unless validation[:success]
      
      ActiveRecord::Base.transaction do
        # Suspend selected devices
        suspend_devices(devices_to_suspend)
        
        # Cancel the slot
        execute_slot_cancellation(slot)
      end
    end

    # ===== SLOT INFORMATION =====

    def list_user_slots
      return [] unless subscription
      
      subscription.extra_device_slots.active.order(:created_at).map do |slot|
        {
          id: slot.id,
          description: slot.description,
          monthly_cost: slot.monthly_cost,
          activated_at: slot.activated_at,
          display_number: slot.display_number,
          can_cancel: true
        }
      end
    end

    def slot_purchase_info
      {
        can_purchase: can_purchase_slot?,
        cost_per_slot: 5.00,
        currency: 'USD',
        billing_cycle: 'monthly',
        current_extra_slots: subscription&.active_extra_slots_count || 0
      }
    end

    def can_purchase_slot?
      # Always allow slot purchase - never block money!
      subscription&.active? == true
    end

    private

    def slot_manager
      @slot_manager ||= DeviceSlotManager.new(user)
    end

    def find_user_slot(slot_id)
      return nil unless subscription
      subscription.extra_device_slots.active.find_by(id: slot_id)
    end

    def check_over_limit_after_cancellation
      current_used = slot_manager.used_slots
      current_total = slot_manager.total_slots
      total_after_cancellation = current_total - 1
      
      would_be_over_limit = current_used > total_after_cancellation
      excess_count = would_be_over_limit ? (current_used - total_after_cancellation) : 0
      
      {
        would_be_over_limit: would_be_over_limit,
        excess_count: excess_count,
        current_used: current_used,
        total_after_cancellation: total_after_cancellation
      }
    end

    def over_limit_response(over_limit_data)
      {
        success: false,
        needs_device_selection: true,
        message: "Cancelling this slot would put you over your device limit",
        over_limit_data: over_limit_data,
        available_actions: [
          {
            action: 'select_devices',
            description: "Suspend #{over_limit_data[:excess_count]} device(s)",
            required_device_count: over_limit_data[:excess_count]
          },
          {
            action: 'keep_slot',
            description: 'Keep the slot active',
            cost: 'Continue paying $5/month'
          },
          {
            action: 'upgrade_plan',
            description: 'Upgrade to a plan with more included slots',
            available: available_plan_upgrades.any?
          }
        ]
      }
    end

    def validate_device_selection(device_ids, required_count)
      return failure('No devices selected for suspension') if device_ids.empty?
      return failure("Must select exactly #{required_count} device(s) to suspend") if device_ids.length != required_count
      
      # Validate all devices belong to user and can be suspended
      devices = user.devices.operational.where(id: device_ids)
      return failure('One or more selected devices not found or not operational') if devices.count != device_ids.length
      
      success(devices: devices)
    end

    def suspend_devices(device_ids)
      devices = user.devices.operational.where(id: device_ids)
      suspended_devices = []
      
      devices.each do |device|
        if device.suspend!(reason: 'extra_slot_cancellation')
          suspended_devices << {
            id: device.id,
            name: device.name,
            suspended_reason: 'extra_slot_cancellation'
          }
        end
      end
      
      suspended_devices
    end

    def execute_slot_cancellation(slot)
      ActiveRecord::Base.transaction do
        slot.cancel!
        
        # TODO: Cancel Stripe subscription item
        # cancel_stripe_subscription_item(slot)
        
        success(
          message: 'Device slot cancelled successfully',
          slot: {
            id: slot.id,
            description: slot.description,
            cancelled_at: slot.cancelled_at
          },
          new_total_slots: slot_manager.total_slots,
          monthly_cost_decrease: 5.00
        )
      end
    rescue => e
      Rails.logger.error "ExtraSlotManager cancellation error: #{e.message}"
      failure('An error occurred while cancelling the slot')
    end

    def available_plan_upgrades
      return [] unless subscription
      
      current_plan = subscription.plan
      Plan.where('device_limit > ?', current_plan.device_limit)
          .order(:device_limit)
    end

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message)
      { success: false, error: message }
    end

    # TODO: Stripe integration methods
    # def create_stripe_subscription_item(slot)
    #   # Create Stripe subscription item for $5/month
    # end
    
    # def cancel_stripe_subscription_item(slot)
    #   # Cancel Stripe subscription item
    # end
  end
end