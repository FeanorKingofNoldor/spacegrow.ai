# app/services/admin/subscription_service.rb - SIMPLIFIED FOR STARTUP
module Admin
  class SubscriptionService < ApplicationService
    def list_subscriptions(params = {})
      begin
        subscriptions = build_subscriptions_query(params)
        paginated_subscriptions = subscriptions.page(params[:page] || 1).per(25)
        
        success(
          subscriptions: paginated_subscriptions.map { |s| serialize_subscription(s) },
          total: subscriptions.count,
          current_page: paginated_subscriptions.current_page,
          total_pages: paginated_subscriptions.total_pages,
          summary: build_simple_summary(subscriptions)
        )
      rescue => e
        Rails.logger.error "Subscription listing error: #{e.message}"
        failure("Failed to load subscriptions: #{e.message}")
      end
    end

    def subscription_detail(subscription_id)
      begin
        subscription = Subscription.includes(:user, :plan).find(subscription_id)
        
        success(
          subscription: serialize_subscription_detail(subscription),
          user: serialize_subscription_user(subscription.user),
          plan: serialize_subscription_plan(subscription.plan)
        )
      rescue ActiveRecord::RecordNotFound
        failure("Subscription not found")
      rescue => e
        Rails.logger.error "Subscription detail error: #{e.message}"
        failure("Failed to load subscription details: #{e.message}")
      end
    end

    def update_subscription_status(subscription_id, new_status, reason = nil)
      begin
        subscription = Subscription.find(subscription_id)
        
        return failure("Invalid status") unless valid_status?(new_status)
        return failure("Subscription is already #{new_status}") if subscription.status == new_status
        
        old_status = subscription.status
        
        ActiveRecord::Base.transaction do
          subscription.update!(status: new_status)
          
          # Handle status-specific logic
          case new_status
          when 'past_due'
            handle_suspension(subscription, reason)
          when 'active'
            handle_reactivation(subscription)
          when 'canceled'
            handle_cancellation(subscription, reason)
          end
        end
        
        Rails.logger.info "Admin updated subscription #{subscription.id} from #{old_status} to #{new_status}"
        
        success(
          message: "Subscription status updated to #{new_status}",
          subscription: serialize_subscription_detail(subscription)
        )
      rescue ActiveRecord::RecordNotFound
        failure("Subscription not found")
      rescue => e
        Rails.logger.error "Subscription status update error: #{e.message}"
        failure("Failed to update subscription status: #{e.message}")
      end
    end

    private

    # === QUERY BUILDING ===

    def build_subscriptions_query(params)
      subscriptions = Subscription.includes(:user, :plan)
      
      # Filter by status
      if params[:status].present?
        subscriptions = subscriptions.where(status: params[:status])
      end
      
      # Filter by plan
      if params[:plan_id].present?
        subscriptions = subscriptions.where(plan_id: params[:plan_id])
      end
      
      # Filter by user
      if params[:user_id].present?
        subscriptions = subscriptions.where(user_id: params[:user_id])
      end
      
      # Simple search
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        subscriptions = subscriptions.joins(:user).where(
          "users.email ILIKE ? OR subscriptions.id::text = ?",
          search_term, params[:search]
        )
      end
      
      subscriptions.order(created_at: :desc)
    end

    # === SERIALIZATION ===

    def serialize_subscription(subscription)
      {
        id: subscription.id,
        user_email: subscription.user.email,
        plan_name: subscription.plan&.name,
        status: subscription.status,
        monthly_cost: subscription.monthly_cost&.to_f,
        device_limit: subscription.device_limit,
        created_at: subscription.created_at.iso8601
      }
    end

    def serialize_subscription_detail(subscription)
      {
        id: subscription.id,
        status: subscription.status,
        monthly_cost: subscription.monthly_cost&.to_f,
        device_limit: subscription.device_limit,
        created_at: subscription.created_at.iso8601,
        updated_at: subscription.updated_at.iso8601,
        canceled_at: subscription.canceled_at&.iso8601
      }
    end

    def serialize_subscription_user(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        device_count: user.devices.count,
        active_devices: user.devices.where(status: 'active').count
      }
    end

    def serialize_subscription_plan(plan)
      return nil unless plan
      
      {
        id: plan.id,
        name: plan.name,
        monthly_price: plan.monthly_price.to_f,
        device_limit: plan.device_limit
      }
    end

    # === SIMPLE SUMMARY ===

    def build_simple_summary(subscriptions_scope)
      {
        total_subscriptions: subscriptions_scope.count,
        by_status: subscriptions_scope.group(:status).count,
        active_count: subscriptions_scope.where(status: 'active').count,
        past_due_count: subscriptions_scope.where(status: 'past_due').count,
        monthly_revenue: subscriptions_scope.where(status: 'active').joins(:plan).sum('plans.monthly_price').to_f
      }
    end

    # === HELPER METHODS ===

    def valid_status?(status)
      %w[active past_due canceled pending].include?(status)
    end

    def handle_suspension(subscription, reason)
      # Suspend user devices
      subscription.user.devices.where(status: 'active').update_all(
        status: 'suspended',
        updated_at: Time.current
      )
      
      Rails.logger.info "Suspended devices for subscription #{subscription.id}: #{reason}"
    end

    def handle_reactivation(subscription)
      # Reactivate devices up to limit
      device_limit = subscription.device_limit || 5
      subscription.user.devices.where(status: 'suspended')
                   .limit(device_limit)
                   .update_all(
                     status: 'active',
                     updated_at: Time.current
                   )
      
      Rails.logger.info "Reactivated devices for subscription #{subscription.id}"
    end

    def handle_cancellation(subscription, reason)
      # Cancel and suspend all devices
      subscription.update!(canceled_at: Time.current)
      subscription.user.devices.where(status: 'active').update_all(
        status: 'suspended',
        updated_at: Time.current
      )
      
      Rails.logger.info "Canceled subscription #{subscription.id}: #{reason}"
    end
  end
end