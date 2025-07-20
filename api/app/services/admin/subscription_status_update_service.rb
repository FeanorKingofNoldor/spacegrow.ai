# app/services/admin/subscription_status_update_service.rb
module Admin
  class SubscriptionStatusUpdateService < ApplicationService
    def initialize(subscription, new_status, reason = nil)
      @subscription = subscription
      @new_status = new_status
      @reason = reason
    end

    def call
      begin
        validate_status_change
        perform_status_update
        
        success(
          message: "Subscription status updated from #{@old_status} to #{@new_status}",
          subscription: serialize_subscription_detail(@subscription.reload),
          status_change: {
            old_status: @old_status,
            new_status: @new_status,
            reason: @reason,
            changed_at: Time.current.iso8601,
            changed_by: current_admin_id
          }
        )
      rescue => e
        Rails.logger.error "Subscription status update error: #{e.message}"
        failure("Failed to update subscription status: #{e.message}")
      end
    end

    private

    attr_reader :subscription, :new_status, :reason

    def validate_status_change
      unless %w[active past_due canceled].include?(new_status)
        raise ArgumentError, "Invalid status: #{new_status}"
      end
      
      if subscription.status == new_status
        raise ArgumentError, "Subscription is already #{new_status}"
      end
    end

    def perform_status_update
      @old_status = subscription.status
      
      ActiveRecord::Base.transaction do
        subscription.update!(status: new_status)
        
        # Handle status-specific logic using existing services
        case new_status
        when 'past_due'
          handle_admin_suspension
        when 'active'
          handle_admin_reactivation
        when 'canceled'
          handle_admin_cancellation
        end
        
        # Log admin action
        log_admin_subscription_action
      end
    end

    def handle_admin_suspension
      # Suspend user devices but keep data
      state_manager = Billing::DeviceStateManager.new(subscription.user)
      state_manager.suspend_devices(
        subscription.user.devices.active.pluck(:id),
        reason: "Subscription past due - admin action: #{reason}"
      )
    end

    def handle_admin_reactivation
      # Reactivate devices within subscription limits
      slot_manager = Billing::DeviceSlotManager.new(subscription.user)
      state_manager = Billing::DeviceStateManager.new(subscription.user)
      
      # Get suspended devices that can be reactivated
      suspended_devices = subscription.user.devices.suspended
      slot_summary = slot_manager.slot_summary
      
      devices_to_reactivate = suspended_devices.limit(slot_summary[:available_slots])
      
      if devices_to_reactivate.any?
        state_manager.wake_devices(
          devices_to_reactivate.pluck(:id)
        )
      end
    end

    def handle_admin_cancellation
      # Cancel subscription and handle device states
      subscription.update!(canceled_at: Time.current)
      
      # Suspend all user devices
      state_manager = Billing::DeviceStateManager.new(subscription.user)
      state_manager.suspend_devices(
        subscription.user.devices.active.pluck(:id),
        reason: "Subscription canceled - admin action: #{reason}"
      )
      
      # Expire activation tokens
      DeviceManagement::ActivationTokenService.expire_for_subscription(subscription)
    end

    def log_admin_subscription_action
      AdminActivityLog.create!(
        admin_user_id: current_admin_id,
        target_type: 'Subscription',
        target_id: subscription.id,
        action: 'status_change',
        metadata: {
          old_status: @old_status,
          new_status: new_status,
          reason: reason,
          user_email: subscription.user.email,
          subscription_plan: subscription.plan&.name
        }
      )
      
      Rails.logger.info "Admin Subscription Action: status_change on subscription #{subscription.id} from #{@old_status} to #{new_status}"
    end

    def serialize_subscription_detail(subscription)
      {
        id: subscription.id,
        status: subscription.status,
        plan_name: subscription.plan&.name,
        user_email: subscription.user.email,
        monthly_cost: subscription.monthly_cost,
        device_limit: subscription.device_limit,
        created_at: subscription.created_at.iso8601,
        updated_at: subscription.updated_at.iso8601,
        canceled_at: subscription.canceled_at&.iso8601
      }
    end

    def current_admin_id
      # This would be set from the controller context
      # For now, using a placeholder
      1 # Would be passed from controller or stored in context
    end
  end
end