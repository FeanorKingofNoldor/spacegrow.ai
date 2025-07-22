# app/services/admin/user_service.rb
module Admin
  class UserService < ApplicationService
    def list_users(params = {})
      begin
        users = build_users_query(params)
        
        success(
          users: users.page(params[:page]).per(25).map { |u| serialize_user(u) },
          total: users.count,
          filters: build_filter_options,
          summary: build_users_summary(users)
        )
      rescue => e
        Rails.logger.error "Admin User List error: #{e.message}"
        failure("Failed to load users: #{e.message}")
      end
    end

    def user_detail(user_id)
      begin
        user = User.includes(:subscription, :devices, :orders).find(user_id)
        
        success(
          user: serialize_user_detail(user),
          devices: serialize_user_devices(user),
          subscription: serialize_user_subscription(user),
          activity: build_user_activity(user),
          quick_actions: build_user_actions(user)
        )
      rescue ActiveRecord::RecordNotFound
        failure("User not found")
      rescue => e
        Rails.logger.error "Admin User Detail error: #{e.message}"
        failure("Failed to load user details: #{e.message}")
      end
    end

    def suspend_user(user_id, reason)
      begin
        user = User.find(user_id)
        
        ActiveRecord::Base.transaction do
          # Update subscription status
          if user.subscription
            user.subscription.update!(status: 'past_due')
          end
          
          # Suspend user devices
          suspended_count = user.devices.active.update_all(
            status: 'suspended',
            updated_at: Time.current
          )
          
          # Log the action
          Rails.logger.info "Admin suspended user #{user.email}: #{reason}"
          
          # Track the action (if you want metrics)
          track_admin_action('user_suspended', user.id, reason)
        end
        
        success(
          message: "User #{user.email} suspended successfully",
          suspended_devices: user.devices.suspended.count
        )
      rescue ActiveRecord::RecordNotFound
        failure("User not found")
      rescue => e
        Rails.logger.error "Admin User Suspension error: #{e.message}"
        failure("Failed to suspend user: #{e.message}")
      end
    end

    def reactivate_user(user_id)
      begin
        user = User.find(user_id)
        
        ActiveRecord::Base.transaction do
          # Reactivate subscription
          if user.subscription
            user.subscription.update!(status: 'active')
          end
          
          # Reactivate devices (up to their limit)
          device_limit = user.device_limit || 5
          reactivated_count = user.devices.suspended
                                  .limit(device_limit)
                                  .update_all(
                                    status: 'active',
                                    updated_at: Time.current
                                  )
          
          Rails.logger.info "Admin reactivated user #{user.email}"
          track_admin_action('user_reactivated', user.id)
        end
        
        success(
          message: "User #{user.email} reactivated successfully",
          reactivated_devices: user.devices.active.count
        )
      rescue ActiveRecord::RecordNotFound
        failure("User not found")
      rescue => e
        Rails.logger.error "Admin User Reactivation error: #{e.message}"
        failure("Failed to reactivate user: #{e.message}")
      end
    end

    def bulk_suspend_users(user_ids, reason)
      begin
        users = User.where(id: user_ids)
        suspended_count = 0
        
        ActiveRecord::Base.transaction do
          users.each do |user|
            user.subscription&.update!(status: 'past_due')
            user.devices.active.update_all(status: 'suspended')
            suspended_count += 1
          end
          
          Rails.logger.info "Admin bulk suspended #{suspended_count} users: #{reason}"
        end
        
        success(
          message: "Successfully suspended #{suspended_count} users",
          suspended_count: suspended_count
        )
      rescue => e
        Rails.logger.error "Admin Bulk Suspension error: #{e.message}"
        failure("Failed to suspend users: #{e.message}")
      end
    end

    private

    def build_users_query(params)
      users = User.includes(:subscription, :devices)
      
      # Search by email
      if params[:search].present?
        users = users.where("email ILIKE ?", "%#{params[:search]}%")
      end
      
      # Filter by role
      if params[:role].present?
        users = users.where(role: params[:role])
      end
      
      # Filter by subscription status
      case params[:status]
      when 'active'
        users = users.joins(:subscription).where(subscriptions: { status: 'active' })
      when 'past_due'
        users = users.joins(:subscription).where(subscriptions: { status: 'past_due' })
      when 'canceled'
        users = users.joins(:subscription).where(subscriptions: { status: 'canceled' })
      when 'no_subscription'
        users = users.left_joins(:subscription).where(subscriptions: { id: nil })
      end
      
      # Filter by plan
      if params[:plan].present?
        users = users.joins(subscription: :plan).where(plans: { name: params[:plan] })
      end
      
      users.order(created_at: :desc)
    end

    def serialize_user(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        role: user.role,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        subscription_status: user.subscription&.status || 'none',
        plan_name: user.subscription&.plan&.name,
        device_count: user.devices.count,
        active_devices: user.devices.where(status: 'active').count
      }
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
        confirmed_at: user.confirmed_at,
        timezone: user.timezone
      }
    end

    def serialize_user_devices(user)
      user.devices.includes(:device_type).map do |device|
        {
          id: device.id,
          name: device.name,
          device_type: device.device_type&.name,
          status: device.status,
          last_connection: device.last_connection,
          created_at: device.created_at
        }
      end
    end

    def serialize_user_subscription(user)
      return nil unless user.subscription
      
      {
        id: user.subscription.id,
        status: user.subscription.status,
        plan_name: user.subscription.plan&.name,
        monthly_cost: user.subscription.monthly_cost,
        device_limit: user.subscription.device_limit,
        created_at: user.subscription.created_at,
        current_period_start: user.subscription.current_period_start,
        current_period_end: user.subscription.current_period_end
      }
    end

    def build_user_activity(user)
      {
        devices_registered: user.devices.count,
        orders_placed: user.orders.count,
        total_spent: user.orders.where(status: 'completed').sum(:total),
        last_device_activity: user.devices.maximum(:last_connection),
        account_age_days: (Time.current - user.created_at).to_i / 1.day
      }
    end

    def build_user_actions(user)
      actions = []
      
      if user.subscription&.active?
        actions << { action: 'suspend', label: 'Suspend User', type: 'warning' }
      elsif user.subscription&.past_due?
        actions << { action: 'reactivate', label: 'Reactivate User', type: 'success' }
      end
      
      actions << { action: 'view_devices', label: 'Manage Devices', type: 'info' }
      actions << { action: 'view_orders', label: 'View Orders', type: 'info' }
      
      actions
    end

    def build_filter_options
      {
        roles: User.roles.keys,
        statuses: ['active', 'past_due', 'canceled', 'no_subscription'],
        plans: Plan.pluck(:name).uniq.compact
      }
    end

    def build_users_summary(users_scope)
      total = users_scope.count
      
      {
        total_users: total,
        by_role: users_scope.group(:role).count,
        with_subscriptions: users_scope.joins(:subscription).count,
        active_subscribers: users_scope.joins(:subscription).where(subscriptions: { status: 'active' }).count,
        recent_signups: users_scope.where(created_at: 7.days.ago..).count
      }
    end

    def track_admin_action(action, user_id, details = nil)
      # Simple logging for now - you could expand this later
      Rails.logger.info "Admin Action: #{action} for user #{user_id} - #{details}"
      
      # If you want to track in Prometheus
      if defined?(Yabeda)
        Yabeda.business.support_tickets.increment(
          tags: { category: 'admin_action', priority: action }
        )
      end
    rescue => e
      Rails.logger.debug "Admin action tracking failed: #{e.message}"
    end
  end
end