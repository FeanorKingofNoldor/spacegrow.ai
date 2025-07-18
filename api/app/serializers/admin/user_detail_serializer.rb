# app/serializers/admin/user_detail_serializer.rb
module Admin
  class UserDetailSerializer
    include ActiveModel::Serialization

    def self.serialize(user, include_sensitive: true)
      base_data = {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        status: user.admin_status,
        created_at: user.created_at.iso8601,
        last_sign_in_at: user.last_sign_in_at&.iso8601,
        timezone: user.timezone,
        
        # Device information
        device_summary: user.admin_device_summary,
        
        # Subscription information
        subscription: serialize_subscription(user.subscription),
        
        # Activity metrics
        activity_metrics: {
          sign_in_count: user.sign_in_count,
          last_activity: user.last_sign_in_at,
          account_age_days: (Time.current - user.created_at).to_i / 1.day
        },
        
        # Flags and risk factors
        flags: user.admin_flags,
        risk_factors: user.admin_risk_factors
      }

      if include_sensitive
        base_data.merge!(
          financial_summary: user.admin_financial_summary,
          subscription_history: user.admin_subscription_history,
          recent_activity: user.admin_activity_timeline(5)
        )
      end

      base_data
    end

    def self.serialize_list(users)
      users.map { |user| serialize_compact(user) }
    end

    def self.serialize_compact(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        role: user.role,
        status: user.admin_status,
        created_at: user.created_at.iso8601,
        last_sign_in_at: user.last_sign_in_at&.iso8601,
        device_count: user.devices.count,
        device_limit: user.device_limit,
        subscription_plan: user.subscription&.plan&.name,
        risk_level: determine_risk_level(user)
      }
    end

    private

    def self.serialize_subscription(subscription)
      return nil unless subscription

      {
        id: subscription.id,
        plan_name: subscription.plan&.name,
        status: subscription.status,
        device_limit: subscription.device_limit,
        monthly_cost: subscription.monthly_cost,
        created_at: subscription.created_at.iso8601,
        current_period_start: subscription.current_period_start&.iso8601,
        current_period_end: subscription.current_period_end&.iso8601
      }
    end

    def self.determine_risk_level(user)
      risk_factors = user.admin_risk_factors
      
      return 'high' if risk_factors.include?('payment_past_due') || risk_factors.include?('multiple_failed_orders')
      return 'medium' if risk_factors.include?('inactive_user') || risk_factors.include?('over_device_limit')
      'low'
    end
  end
end