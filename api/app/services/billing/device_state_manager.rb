# app/services/billing/device_state_manager.rb
module Billing
  class DeviceStateManager < ApplicationService
    include ActiveModel::Model
    
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # ===== DEVICE ACTIVATION =====
    
    def activate_device(device)
      return failure('Device not found or not owned by user') unless owns_device?(device)
      return failure('Device is already active') if device.active?
      return failure('Device is disabled') if device.disabled?
      
      # Check if user has available slots
      slot_manager = DeviceSlotManager.new(user)
      unless slot_manager.can_activate_device?
        return over_limit_response(slot_manager)
      end
      
      # Activate the device
      if device.update(status: 'active')
        success(
          message: 'Device activated successfully',
          device: device_summary(device),
          slot_usage: slot_manager.slot_summary
        )
      else
        failure("Failed to activate device: #{device.errors.full_messages.join(', ')}")
      end
    end

    # ===== DEVICE SUSPENSION =====
    
    def suspend_device(device, reason: 'user_request')
      return failure('Device not found or not owned by user') unless owns_device?(device)
      return failure('Device is already suspended') if device.suspended?
      return failure('Device is not active') unless device.active?
      
      if device.suspend!(reason: reason)
        success(
          message: 'Device suspended successfully',
          device: device_summary(device),
          suspension_details: {
            reason: reason,
            suspended_at: device.suspended_at,
            grace_period_ends_at: device.grace_period_ends_at,
            can_wake: true
          }
        )
      else
        failure("Failed to suspend device: #{device.errors.full_messages.join(', ')}")
      end
    end

    # ===== DEVICE WAKE (UNSUSPEND) =====
    
    def wake_device(device)
      return failure('Device not found or not owned by user') unless owns_device?(device)
      return failure('Device is not suspended') unless device.suspended?
      
      # Check if user has available slots
      slot_manager = DeviceSlotManager.new(user)
      unless slot_manager.can_activate_device?
        return over_limit_response(slot_manager)
      end
      
      if device.wake!
        success(
          message: 'Device woken up successfully',
          device: device_summary(device),
          slot_usage: slot_manager.slot_summary
        )
      else
        failure("Failed to wake device: #{device.errors.full_messages.join(', ')}")
      end
    end

    # ===== BULK OPERATIONS =====
    
    def suspend_devices(device_ids, reason: 'bulk_suspension')
      devices = user.devices.operational.where(id: device_ids)
      return failure('No valid devices found') if devices.empty?
      
      suspended_devices = []
      failed_devices = []
      
      ActiveRecord::Base.transaction do
        devices.each do |device|
          if device.suspend!(reason: reason)
            suspended_devices << device_summary(device)
          else
            failed_devices << { id: device.id, name: device.name, errors: device.errors.full_messages }
          end
        end
      end
      
      if failed_devices.empty?
        success(
          message: "Successfully suspended #{suspended_devices.count} device(s)",
          suspended_devices: suspended_devices,
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      else
        partial_success(
          message: "Suspended #{suspended_devices.count} device(s), #{failed_devices.count} failed",
          suspended_devices: suspended_devices,
          failed_devices: failed_devices
        )
      end
    end

    def wake_devices(device_ids)
      devices = user.devices.suspended.where(id: device_ids)
      return failure('No suspended devices found') if devices.empty?
      
      slot_manager = DeviceSlotManager.new(user)
      available_slots = slot_manager.available_slots
      
      if available_slots < devices.count
        return failure("Not enough available slots. You have #{available_slots} available but trying to wake #{devices.count} devices")
      end
      
      woken_devices = []
      failed_devices = []
      
      ActiveRecord::Base.transaction do
        devices.each do |device|
          if device.wake!
            woken_devices << device_summary(device)
          else
            failed_devices << { id: device.id, name: device.name, errors: device.errors.full_messages }
          end
        end
      end
      
      if failed_devices.empty?
        success(
          message: "Successfully woken #{woken_devices.count} device(s)",
          woken_devices: woken_devices,
          slot_usage: DeviceSlotManager.new(user).slot_summary
        )
      else
        partial_success(
          message: "Woken #{woken_devices.count} device(s), #{failed_devices.count} failed",
          woken_devices: woken_devices,
          failed_devices: failed_devices
        )
      end
    end

    # ===== DEVICE INFORMATION =====
    
    def device_states_summary
      {
        active: user.devices.active.count,
        suspended: user.devices.suspended.count,
        pending: user.devices.pending.count,
        disabled: user.devices.disabled.count,
        total: user.devices.count
      }
    end

    def devices_by_state
      {
        active: user.devices.active.map { |d| device_summary(d) },
        suspended: user.devices.suspended.map { |d| device_summary(d) },
        pending: user.devices.pending.map { |d| device_summary(d) },
        disabled: user.devices.disabled.map { |d| device_summary(d) }
      }
    end

    def devices_available_for_suspension
      user.devices.operational.map { |device| device_summary(device) }
    end

    def devices_available_for_waking
      user.devices.suspended.map { |device| device_summary(device) }
    end

    private

    def owns_device?(device)
      device&.user_id == user.id
    end

    def device_summary(device)
      {
        id: device.id,
        name: device.name,
        status: device.status,
        device_type: device.device_type&.name,
        last_connection: device.last_connection,
        suspended_at: device.suspended_at,
        suspended_reason: device.suspended_reason,
        grace_period_ends_at: device.grace_period_ends_at,
        can_suspend: device.active?,
        can_wake: device.suspended?,
        can_activate: device.pending?
      }
    end

    def over_limit_response(slot_manager)
      summary = slot_manager.slot_summary
      
      {
        success: false,
        over_limit: true,
        message: "Cannot activate device: at device limit (#{summary[:used_slots]}/#{summary[:total_slots]} slots used)",
        slot_usage: summary,
        available_actions: [
          {
            action: 'buy_extra_slot',
            description: 'Purchase extra device slot (+$5/month)',
            cost: 5.00
          },
          {
            action: 'suspend_device',
            description: 'Suspend another device first',
            available_devices: devices_available_for_suspension.count
          },
          {
            action: 'upgrade_plan',
            description: 'Upgrade to a plan with more device slots',
            available: available_plan_upgrades.any?
          }
        ]
      }
    end

    def available_plan_upgrades
      return [] unless user.subscription
      
      current_plan = user.subscription.plan
      Plan.where('device_limit > ?', current_plan.device_limit).order(:device_limit)
    end

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message)
      { success: false, error: message }
    end

    def partial_success(data)
      { success: true, partial: true }.merge(data)
    end
  end
end