# app/services/admin/user_service.rb - SIMPLIFIED FOR STARTUP
module Admin
  class UserService < ApplicationService
    def list_users(params = {})
      begin
        users = build_users_query(params)
        paginated_users = users.page(params[:page] || 1).per(25)
        
        success(
          users: paginated_users.map { |u| serialize_user(u) },
          total: users.count,
          current_page: paginated_users.current_page,
          total_pages: paginated_users.total_pages,
          summary: build_simple_summary(users)
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
          orders: serialize_user_orders(user)
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
          # Update subscription status if exists
          if user.subscription
            user.subscription.update!(status: 'past_due')
          end
          
          # Suspend user devices
          suspended_count = user.devices.where(status: 'active').update_all(
            status: 'suspended',
            updated_at: Time.current
          )
          
          Rails.logger.info "Admin suspended user #{user.email}: #{reason}"
        end
        
        success(
          message: "User #{user.email} suspended successfully",
          suspended_devices: user.devices.where(status: 'suspended').count
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
          # Reactivate subscription if exists
          if user.subscription
            user.subscription.update!(status: 'active')
          end
          
          # Reactivate devices (up to limit)
          device_limit = user.device_limit || 5
          reactivated_count = user.devices.where(status: 'suspended')
                                  .limit(device_limit)
                                  .update_all(
                                    status: 'active',
                                    updated_at: Time.current
                                  )
          
          Rails.logger.info "Admin reactivated user #{user.email}"
        end
        
        success(
          message: "User #{user.email} reactivated successfully",
          reactivated_devices: user.devices.where(status: 'active').count
        )
      rescue ActiveRecord::RecordNotFound
        failure("User not found")
      rescue => e
        Rails.logger.error "Admin User Reactivation error: #{e.message}"
        failure("Failed to reactivate user: #{e.message}")
      end
    end

    private

    # === SIMPLE QUERY BUILDING ===

    def build_users_query(params)
      users = User.includes(:subscription, :devices)
      
      # Simple search by email or name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        users = users.where(
          "email ILIKE ? OR display_name ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
          search_term, search_term, search_term, search_term
        )
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

    # === SIMPLE SERIALIZATION ===

    def serialize_user(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        role: user.role,
        created_at: user.created_at.iso8601,
        last_sign_in_at: user.last_sign_in_at&.iso8601,
        subscription_status: user.subscription&.status || 'none',
        plan_name: user.subscription&.plan&.name,
        device_count: user.devices.count,
        total_spent: user.orders.where(status: 'completed').sum(:total).to_f
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
        created_at: user.created_at.iso8601,
        last_sign_in_at: user.last_sign_in_at&.iso8601,
        sign_in_count: user.sign_in_count,
        confirmed_at: user.confirmed_at&.iso8601,
        timezone: user.timezone
      }
    end

    def serialize_user_devices(user)
      user.devices.includes(:device_type).limit(10).map do |device|
        {
          id: device.id,
          name: device.name,
          device_type: device.device_type&.name,
          status: device.status,
          last_connection: device.last_connection&.iso8601,
          created_at: device.created_at.iso8601
        }
      end
    end

    def serialize_user_subscription(user)
      return nil unless user.subscription
      
      {
        id: user.subscription.id,
        status: user.subscription.status,
        plan_name: user.subscription.plan&.name,
        monthly_cost: user.subscription.monthly_cost&.to_f,
        device_limit: user.subscription.device_limit,
        created_at: user.subscription.created_at.iso8601
      }
    end

    def serialize_user_orders(user)
      user.orders.order(created_at: :desc).limit(5).map do |order|
        {
          id: order.id,
          status: order.status,
          total: order.total.to_f,
          created_at: order.created_at.iso8601
        }
      end
    end

    # === SIMPLE SUMMARY ===

    def build_simple_summary(users_scope)
      total = users_scope.count
      
      {
        total_users: total,
        with_subscriptions: users_scope.joins(:subscription).count,
        active_subscribers: users_scope.joins(:subscription).where(subscriptions: { status: 'active' }).count,
        past_due_subscribers: users_scope.joins(:subscription).where(subscriptions: { status: 'past_due' }).count,
        recent_signups: users_scope.where(created_at: 7.days.ago..).count
      }
    end
  end
end