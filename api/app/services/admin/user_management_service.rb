# app/services/admin/user_management_service.rb
module Admin
  class UserManagementService < ApplicationService
    def initialize(admin_user_id = nil)
      @admin_user_id = admin_user_id
    end

    def search_and_filter_users(params)
      begin
        users = User.includes(:subscription, :plan, :devices)
        
        # Apply search
        users = apply_search_filter(users, params[:search]) if params[:search].present?
        
        # Apply filters
        users = apply_role_filter(users, params[:role]) if params[:role].present?
        users = apply_status_filter(users, params[:status]) if params[:status].present?
        users = apply_plan_filter(users, params[:plan]) if params[:plan].present?
        users = apply_date_filters(users, params)
        
        # Apply sorting
        users = apply_sorting(users, params[:sort_by], params[:sort_direction])
        
        # Pagination
        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 25, 100].min
        
        paginated_users = users.page(page).per(per_page)
        
        success(
          users: serialize_users_list(paginated_users),
          pagination: {
            current_page: page,
            per_page: per_page,
            total_pages: paginated_users.total_pages,
            total_count: paginated_users.total_count
          },
          filters: build_filter_options,
          summary: build_users_summary(users)
        )
      rescue => e
        Rails.logger.error "User search error: #{e.message}"
        failure("Failed to search users: #{e.message}")
      end
    end

    def user_detailed_view(user)
      begin
        # Get comprehensive user data
        user_data = serialize_user_detail(user)
        
        # Device information
        device_summary = build_device_summary(user)
        
        # Subscription history
        subscription_history = build_subscription_history(user)
        
        # Activity metrics
        activity_metrics = build_activity_metrics(user)
        
        # Recent activity
        recent_activity = build_recent_activity(user)
        
        success(
          user: user_data,
          device_summary: device_summary,
          subscription_history: subscription_history,
          activity_metrics: activity_metrics,
          recent_activity: recent_activity,
          available_actions: build_available_actions(user)
        )
      rescue => e
        Rails.logger.error "User detail view error: #{e.message}"
        failure("Failed to load user details: #{e.message}")
      end
    end

    def change_user_role(user, new_role)
      begin
        return failure("Invalid role") unless User.roles.key?(new_role)
        return failure("User is already #{new_role}") if user.role == new_role
        
        old_role = user.role
        
        ActiveRecord::Base.transaction do
          user.update!(role: new_role)
          
          # Log the role change
          log_admin_action(user, 'role_change', {
            old_role: old_role,
            new_role: new_role,
            changed_by: current_admin_id
          })
          
          # Handle role-specific logic
          handle_role_change_effects(user, old_role, new_role)
        end
        
        success(
          message: "User role changed from #{old_role} to #{new_role}",
          user: serialize_user_detail(user),
          role_change: {
            old_role: old_role,
            new_role: new_role,
            changed_at: Time.current
          }
        )
      rescue => e
        Rails.logger.error "Role change error: #{e.message}"
        failure("Failed to change user role: #{e.message}")
      end
    end

    def suspend_user(user, reason = nil)
      begin
        return failure("User is already suspended") if user_suspended?(user)
        
        ActiveRecord::Base.transaction do
          # Suspend user's subscription if active
          if user.subscription&.active?
            state_manager = Billing::DeviceStateManager.new(user)
            state_manager.suspend_devices(user.devices.active.pluck(:id), reason: 'account_suspension')
            
            user.subscription.update!(status: 'past_due') # Soft suspension
          end
          
          # Mark user as suspended (you might need a suspended field)
          # user.update!(suspended: true, suspended_at: Time.current, suspension_reason: reason)
          
          # Log the suspension
          log_admin_action(user, 'user_suspension', {
            reason: reason,
            suspended_by: current_admin_id,
            suspended_at: Time.current
          })
          
          # Send notification
          send_suspension_notification(user, reason)
        end
        
        success(
          message: "User suspended successfully",
          user: serialize_user_detail(user.reload),
          suspension_details: {
            reason: reason,
            suspended_at: Time.current,
            devices_affected: user.devices.suspended.count
          }
        )
      rescue => e
        Rails.logger.error "User suspension error: #{e.message}"
        failure("Failed to suspend user: #{e.message}")
      end
    end

    def reactivate_user(user)
      begin
        return failure("User is not suspended") unless user_suspended?(user)
        
        ActiveRecord::Base.transaction do
          # Reactivate subscription
          if user.subscription&.past_due?
            user.subscription.update!(status: 'active')
            
            # Wake up devices if user has available slots
            slot_manager = Billing::DeviceSlotManager.new(user)
            if slot_manager.can_activate_device?
              state_manager = Billing::DeviceStateManager.new(user)
              suspended_devices = user.devices.suspended.limit(slot_manager.available_slots)
              state_manager.wake_devices(suspended_devices.pluck(:id))
            end
          end
          
          # Mark user as active
          # user.update!(suspended: false, suspended_at: nil, suspension_reason: nil)
          
          # Log the reactivation
          log_admin_action(user, 'user_reactivation', {
            reactivated_by: current_admin_id,
            reactivated_at: Time.current
          })
          
          # Send notification
          send_reactivation_notification(user)
        end
        
        success(
          message: "User reactivated successfully",
          user: serialize_user_detail(user.reload),
          reactivation_details: {
            reactivated_at: Time.current,
            devices_reactivated: user.devices.active.count
          }
        )
      rescue => e
        Rails.logger.error "User reactivation error: #{e.message}"
        failure("Failed to reactivate user: #{e.message}")
      end
    end

    def user_activity_log(user, page = 1)
      begin
        # This would integrate with your existing activity logging system
        # For now, return sample structure
        activities = build_activity_log(user, page)
        
        success(
          activities: activities,
          pagination: {
            current_page: page.to_i,
            total_pages: 5, # Calculate based on actual data
            total_count: 47 # Calculate based on actual data
          }
        )
      rescue => e
        Rails.logger.error "Activity log error: #{e.message}"
        failure("Failed to load activity log: #{e.message}")
      end
    end

    def bulk_user_operations(operation, user_ids, params)
      begin
        users = User.where(id: user_ids)
        return failure("No valid users found") if users.empty?
        
        results = []
        failed_operations = []
        
        users.find_each do |user|
          case operation
          when 'change_role'
            result = change_user_role(user, params[:role])
          when 'suspend'
            result = suspend_user(user, params[:reason])
          when 'send_notification'
            result = send_bulk_notification(user, params[:notification_message])
          else
            failed_operations << { user_id: user.id, error: "Unknown operation: #{operation}" }
            next
          end
          
          if result[:success]
            results << { user_id: user.id, status: 'success' }
          else
            failed_operations << { user_id: user.id, error: result[:error] }
          end
        end
        
        success(
          message: "Bulk operation completed",
          operation: operation,
          successful_operations: results.count,
          failed_operations: failed_operations.count,
          results: results,
          failures: failed_operations
        )
      rescue => e
        Rails.logger.error "Bulk operation error: #{e.message}"
        failure("Failed to perform bulk operation: #{e.message}")
      end
    end

    private

    # ===== SEARCH AND FILTER HELPERS =====

	attr_reader :admin_user_id
    
    def apply_search_filter(users, search_term)
      users.where(
        "email ILIKE ? OR display_name ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
        "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"
      )
    end

    def apply_role_filter(users, role)
      users.where(role: role)
    end

    def apply_status_filter(users, status)
      case status
      when 'active'
        users.joins(:subscription).where(subscriptions: { status: 'active' })
      when 'suspended'
        users.joins(:subscription).where(subscriptions: { status: 'past_due' })
      when 'canceled'
        users.joins(:subscription).where(subscriptions: { status: 'canceled' })
      when 'no_subscription'
        users.left_joins(:subscription).where(subscriptions: { id: nil })
      else
        users
      end
    end

    def apply_plan_filter(users, plan)
      users.joins(subscription: :plan).where(plans: { name: plan })
    end

    def apply_date_filters(users, params)
      users = users.where(created_at: params[:created_after]..) if params[:created_after].present?
      users = users.where(created_at: ..params[:created_before]) if params[:created_before].present?
      users = users.where(last_sign_in_at: params[:last_login_after]..) if params[:last_login_after].present?
      users = users.where(last_sign_in_at: ..params[:last_login_before]) if params[:last_login_before].present?
      users
    end

    def apply_sorting(users, sort_by, direction)
      direction = direction&.downcase == 'desc' ? :desc : :asc
      
      case sort_by
      when 'email'
        users.order(email: direction)
      when 'created_at'
        users.order(created_at: direction)
      when 'last_sign_in_at'
        users.order(last_sign_in_at: direction)
      when 'role'
        users.order(role: direction)
      else
        users.order(created_at: :desc)
      end
    end

    # ===== SERIALIZATION METHODS =====
    
    def serialize_users_list(users)
      users.map do |user|
        {
          id: user.id,
          email: user.email,
          display_name: user.display_name,
          role: user.role,
          created_at: user.created_at,
          last_sign_in_at: user.last_sign_in_at,
          subscription: user.subscription ? {
            plan_name: user.subscription.plan&.name,
            status: user.subscription.status
          } : nil,
          device_count: user.devices.count,
          device_limit: user.device_limit,
          status: determine_user_status(user)
        }
      end
    end

    def serialize_user_detail(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        sign_in_count: user.sign_in_count,
        timezone: user.timezone,
        status: determine_user_status(user),
        subscription: user.subscription ? serialize_subscription(user.subscription) : nil,
        device_limit: user.device_limit,
        available_slots: user.available_device_slots
      }
    end

    def serialize_subscription(subscription)
      {
        id: subscription.id,
        plan_name: subscription.plan&.name,
        status: subscription.status,
        created_at: subscription.created_at,
        current_period_start: subscription.current_period_start,
        current_period_end: subscription.current_period_end,
        device_limit: subscription.device_limit,
        monthly_cost: subscription.monthly_cost
      }
    end

    # ===== BUILDER METHODS =====
    
    def build_filter_options
      {
        roles: User.roles.keys,
        statuses: ['active', 'suspended', 'canceled', 'no_subscription'],
        plans: Plan.pluck(:name).uniq
      }
    end

    def build_users_summary(users_scope)
      {
        total_users: users_scope.count,
        by_role: users_scope.group(:role).count,
        by_status: calculate_status_distribution(users_scope),
        recent_signups: users_scope.where(created_at: 7.days.ago..Time.current).count
      }
    end

    def build_device_summary(user)
      devices = user.devices.includes(:device_type)
      
      {
        total_devices: devices.count,
        active_devices: devices.active.count,
        suspended_devices: devices.suspended.count,
        device_limit: user.device_limit,
        utilization_rate: calculate_device_utilization(user),
        device_types: devices.group(:device_type_id).count
      }
    end

    def build_subscription_history(user)
      subscriptions = user.subscriptions.includes(:plan).order(created_at: :desc)
      
      subscriptions.map do |sub|
        {
          id: sub.id,
          plan_name: sub.plan&.name,
          status: sub.status,
          created_at: sub.created_at,
          updated_at: sub.updated_at,
          monthly_cost: sub.monthly_cost
        }
      end
    end

    def build_activity_metrics(user)
      {
        devices_registered: user.devices.count,
        last_device_activity: user.devices.maximum(:last_connection),
        orders_placed: user.orders.count,
        total_spent: user.orders.where(status: 'completed').sum(:total),
        support_tickets: 0 # Implement based on your support system
      }
    end

    def build_recent_activity(user, limit = 10)
      activities = []
      
      # Recent device registrations
      user.devices.recent.limit(3).each do |device|
        activities << {
          type: 'device_registered',
          description: "Registered device: #{device.name}",
          timestamp: device.created_at,
          metadata: { device_id: device.id }
        }
      end
      
      # Recent orders
      user.orders.recent.limit(3).each do |order|
        activities << {
          type: 'order_placed',
          description: "Placed order ##{order.id} (#{order.status})",
          timestamp: order.created_at,
          metadata: { order_id: order.id, total: order.total }
        }
      end
      
      # Recent subscription changes
      user.subscriptions.recent.limit(2).each do |sub|
        activities << {
          type: 'subscription_change',
          description: "Subscription: #{sub.plan&.name} (#{sub.status})",
          timestamp: sub.created_at,
          metadata: { subscription_id: sub.id }
        }
      end
      
      activities.sort_by { |a| a[:timestamp] }.reverse.first(limit)
    end

    def build_available_actions(user)
      actions = []
      
      actions << 'change_role' unless user.admin?
      actions << 'suspend' unless user_suspended?(user)
      actions << 'reactivate' if user_suspended?(user)
      actions << 'send_notification'
      actions << 'view_devices'
      actions << 'view_orders'
      
      actions
    end

    def build_activity_log(user, page)
      # This would integrate with your activity logging system
      # Sample structure:
      [
        {
          id: 1,
          type: 'login',
          description: 'User logged in',
          timestamp: 2.hours.ago,
          ip_address: '192.168.1.1',
          user_agent: 'Mozilla/5.0...'
        },
        {
          id: 2,
          type: 'device_registered',
          description: 'Registered new device: Temperature Sensor #3',
          timestamp: 1.day.ago,
          metadata: { device_id: 123 }
        }
      ]
    end

    # ===== HELPER METHODS =====
    
    def determine_user_status(user)
      return 'suspended' if user_suspended?(user)
      return 'active' if user.subscription&.active?
      return 'past_due' if user.subscription&.past_due?
      return 'canceled' if user.subscription&.canceled?
      'no_subscription'
    end

    def user_suspended?(user)
      # Implement based on your suspension logic
      # This might check a suspended field or subscription status
      user.subscription&.past_due? && user.devices.suspended.any?
    end

    def calculate_status_distribution(users_scope)
      # Calculate distribution of user statuses
      {
        active: users_scope.joins(:subscription).where(subscriptions: { status: 'active' }).count,
        suspended: users_scope.joins(:subscription).where(subscriptions: { status: 'past_due' }).count,
        canceled: users_scope.joins(:subscription).where(subscriptions: { status: 'canceled' }).count,
        no_subscription: users_scope.left_joins(:subscription).where(subscriptions: { id: nil }).count
      }
    end

    def calculate_device_utilization(user)
      return 0 if user.device_limit == 0
      ((user.devices.active.count.to_f / user.device_limit) * 100).round(1)
    end

    def handle_role_change_effects(user, old_role, new_role)
      # Handle any role-specific logic
      # For example, if downgrading from enterprise to pro, might need to suspend excess devices
      
      # This would integrate with your existing DeviceSlotManager logic
      slot_manager = Billing::DeviceSlotManager.new(user.reload)
      
      if slot_manager.used_slots > slot_manager.total_slots
        # Need to suspend excess devices
        excess_count = slot_manager.used_slots - slot_manager.total_slots
        devices_to_suspend = user.devices.active.limit(excess_count)
        
        state_manager = Billing::DeviceStateManager.new(user)
        state_manager.suspend_devices(devices_to_suspend.pluck(:id), reason: 'role_downgrade')
      end
    end

    def log_admin_action(user, action, metadata = {})
      # This would integrate with your admin activity logging system
      # You might have an AdminActivityLog model
      Rails.logger.info "Admin Action: #{action} on user #{user.id} - #{metadata}"
    end

    def send_suspension_notification(user, reason)
      # This would integrate with your existing email system
      Rails.logger.info "Sending suspension notification to user #{user.id}"
    end

    def send_reactivation_notification(user)
      # This would integrate with your existing email system
      Rails.logger.info "Sending reactivation notification to user #{user.id}"
    end

    def send_bulk_notification(user, message)
      # This would integrate with your existing notification system
      Rails.logger.info "Sending bulk notification to user #{user.id}: #{message}"
      success(message: "Notification sent")
    end

    def current_admin_id
      admin_user_id || raise ArgumentError, "Admin user ID is required for admin operations"
    end
  end
end