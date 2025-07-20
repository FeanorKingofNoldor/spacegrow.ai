# app/services/admin/subscription_plan_change_service.rb
module Admin
  class SubscriptionPlanChangeService < ApplicationService
    def initialize(subscription, target_plan, interval = 'month')
      @subscription = subscription
      @target_plan = target_plan
      @interval = interval
    end

    def call
      begin
        validate_plan_change
        perform_plan_change
        
        success(
          message: "Plan changed from #{@old_plan.name} to #{@target_plan.name}",
          subscription: serialize_updated_subscription,
          plan_change: {
            old_plan: serialize_plan(@old_plan),
            new_plan: serialize_plan(@target_plan),
            interval: @interval,
            changed_at: Time.current.iso8601,
            changed_by: current_admin_id,
            admin_override: true
          },
          device_impact: analyze_device_impact
        )
      rescue => e
        Rails.logger.error "Admin plan change error: #{e.message}"
        failure("Failed to change plan: #{e.message}")
      end
    end

    private

    attr_reader :subscription, :target_plan, :interval

    def validate_plan_change
      unless subscription.active?
        raise ArgumentError, "Can only change plans for active subscriptions"
      end
      
      if subscription.plan_id == target_plan.id
        raise ArgumentError, "Subscription is already on the #{target_plan.name} plan"
      end
      
      unless target_plan.active?
        raise ArgumentError, "Target plan #{target_plan.name} is not available"
      end
    end

    def perform_plan_change
      @old_plan = subscription.plan
      
      ActiveRecord::Base.transaction do
        # Use existing PlanChangeWorkflow but with admin override
        workflow = Billing::PlanChangeWorkflow.new(subscription.user)
        result = workflow.execute_plan_change(
          target_plan, 
          interval, 
          admin_override: true
        )
        
        unless result[:success]
          raise StandardError, result[:error]
        end
        
        # Handle device limit changes
        handle_device_limit_changes
        
        # Log admin action
        log_admin_plan_change
        
        # Send notification to user
        send_plan_change_notification
      end
    end

    def handle_device_limit_changes
      old_device_limit = @old_plan.device_limit
      new_device_limit = target_plan.device_limit
      user = subscription.user
      current_device_count = user.devices.count
      
      if new_device_limit < old_device_limit && current_device_count > new_device_limit
        # Need to suspend excess devices
        excess_count = current_device_count - new_device_limit
        devices_to_suspend = user.devices.active.order(last_connection: :asc).limit(excess_count)
        
        if devices_to_suspend.any?
          state_manager = Billing::DeviceStateManager.new(user)
          result = state_manager.suspend_devices(
            devices_to_suspend.pluck(:id),
            reason: "Plan downgrade - device limit reduced from #{old_device_limit} to #{new_device_limit}"
          )
          
          @device_suspension_result = result
        end
      elsif new_device_limit > old_device_limit && user.devices.suspended.any?
        # Can reactivate some suspended devices
        available_slots = new_device_limit - user.devices.active.count
        devices_to_reactivate = user.devices.suspended.order(updated_at: :desc).limit(available_slots)
        
        if devices_to_reactivate.any?
          state_manager = Billing::DeviceStateManager.new(user)
          result = state_manager.wake_devices(devices_to_reactivate.pluck(:id))
          
          @device_reactivation_result = result
        end
      end
    end

    def analyze_device_impact
      old_limit = @old_plan.device_limit
      new_limit = target_plan.device_limit
      current_devices = subscription.user.devices.count
      active_devices = subscription.user.devices.active.count
      
      impact = {
        old_device_limit: old_limit,
        new_device_limit: new_limit,
        current_device_count: current_devices,
        active_device_count: active_devices,
        limit_change: new_limit - old_limit
      }
      
      if new_limit < old_limit && current_devices > new_limit
        excess_devices = current_devices - new_limit
        impact[:devices_affected] = excess_devices
        impact[:action_taken] = "suspended_excess_devices"
        impact[:suspended_devices] = @device_suspension_result if @device_suspension_result
      elsif new_limit > old_limit && subscription.user.devices.suspended.any?
        available_slots = new_limit - active_devices
        reactivatable = [subscription.user.devices.suspended.count, available_slots].min
        impact[:devices_affected] = reactivatable
        impact[:action_taken] = "reactivated_suspended_devices"
        impact[:reactivated_devices] = @device_reactivation_result if @device_reactivation_result
      else
        impact[:action_taken] = "no_device_changes_needed"
      end
      
      impact
    end

    def serialize_updated_subscription
      subscription.reload
      
      {
        id: subscription.id,
        status: subscription.status,
        plan_name: subscription.plan.name,
        plan_id: subscription.plan_id,
        monthly_cost: subscription.monthly_cost,
        device_limit: subscription.device_limit,
        user_email: subscription.user.email,
        updated_at: subscription.updated_at.iso8601
      }
    end

    def serialize_plan(plan)
      {
        id: plan.id,
        name: plan.name,
        monthly_price: plan.monthly_price,
        device_limit: plan.device_limit,
        features: plan.features || []
      }
    end

    def log_admin_plan_change
      AdminActivityLog.create!(
        admin_user_id: current_admin_id,
        target_type: 'Subscription',
        target_id: subscription.id,
        action: 'plan_change',
        metadata: {
          old_plan_id: @old_plan.id,
          old_plan_name: @old_plan.name,
          new_plan_id: target_plan.id,
          new_plan_name: target_plan.name,
          interval: interval,
          admin_override: true,
          user_email: subscription.user.email,
          device_impact: analyze_device_impact
        }
      )
      
      Rails.logger.info "Admin Plan Change: subscription #{subscription.id} changed from #{@old_plan.name} to #{target_plan.name}"
    end

    def send_plan_change_notification
      # Send email notification to user about plan change
      begin
        UserMailer.plan_changed_by_admin(
          subscription.user,
          @old_plan,
          target_plan,
          analyze_device_impact
        ).deliver_later
      rescue => e
        Rails.logger.warn "Failed to send plan change notification: #{e.message}"
      end
    end

    def current_admin_id
      # This would be set from the controller context
      1 # Placeholder - would be passed from controller
    end
  end
end