# app/serializers/admin/dashboard_serializer.rb
module Admin
  class DashboardSerializer
    include ActiveModel::Serialization

    def self.serialize(metrics_data)
      {
        dashboard_metrics: {
          users: serialize_user_metrics(metrics_data[:users]),
          devices: serialize_device_metrics(metrics_data[:devices]),
          revenue: serialize_revenue_metrics(metrics_data[:revenue]),
          support: serialize_support_metrics(metrics_data[:support]),
          system_health: serialize_system_health(metrics_data[:system_health])
        },
        alerts: serialize_alerts(metrics_data[:alerts]),
        summary: serialize_summary(metrics_data[:summary]),
        last_updated: Time.current.iso8601
      }
    end

    private

    def self.serialize_user_metrics(user_data)
      {
        total_users: user_data[:total_users],
        new_today: user_data[:new_today],
        active_subscriptions: user_data[:active_subscriptions],
        churn_risk: user_data[:churn_risk],
        growth_rate: calculate_growth_rate(user_data),
        top_plans: user_data[:top_plans] || {}
      }
    end

    def self.serialize_device_metrics(device_data)
      {
        total_devices: device_data[:total_devices],
        active_devices: device_data[:active_devices],
        offline_devices: device_data[:offline_devices],
        new_today: device_data[:new_today],
        error_devices: device_data[:error_devices],
        fleet_utilization: device_data[:fleet_utilization],
        health_status: determine_fleet_health(device_data)
      }
    end

    def self.serialize_revenue_metrics(revenue_data)
      {
        daily_revenue: format_currency(revenue_data[:daily_revenue]),
        monthly_recurring_revenue: format_currency(revenue_data[:monthly_recurring_revenue]),
        total_revenue_today: format_currency(revenue_data[:total_revenue_today]),
        avg_order_value: format_currency(revenue_data[:avg_order_value]),
        revenue_growth: format_percentage(revenue_data[:revenue_growth])
      }
    end

    def self.serialize_support_metrics(support_data)
      {
        open_tickets: support_data[:open_tickets],
        resolved_today: support_data[:resolved_today],
        avg_response_time: support_data[:avg_response_time],
        satisfaction_score: support_data[:satisfaction_score]
      }
    end

    def self.serialize_system_health(health_data)
      {
        database_status: health_data[:database_status],
        redis_status: health_data[:redis_status],
        sidekiq_status: health_data[:sidekiq_status],
        response_time: health_data[:response_time],
        overall_status: determine_overall_health(health_data)
      }
    end

    def self.serialize_alerts(alerts_data)
      {
        critical: alerts_data[:critical],
        warning: alerts_data[:warning],
        info: alerts_data[:info],
        total: alerts_data[:critical] + alerts_data[:warning] + alerts_data[:info]
      }
    end

    def self.serialize_summary(summary_data)
      {
        users_growth: summary_data[:users_growth],
        revenue_today: format_currency(summary_data[:revenue_today]),
        devices_added: summary_data[:devices_added],
        health_status: summary_data[:health_status]
      }
    end

    # Helper methods
    def self.format_currency(amount)
      return "$0.00" if amount.nil?
      "$#{sprintf('%.2f', amount)}"
    end

    def self.format_percentage(percentage)
      return "0%" if percentage.nil?
      "#{sprintf('%.1f', percentage)}%"
    end

    def self.calculate_growth_rate(user_data)
      # Would calculate actual growth rate
      "+8.2%"
    end

    def self.determine_fleet_health(device_data)
      error_rate = device_data[:error_devices].to_f / device_data[:total_devices].to_f * 100
      offline_rate = device_data[:offline_devices].to_f / device_data[:total_devices].to_f * 100
      
      return 'critical' if error_rate > 10 || offline_rate > 20
      return 'warning' if error_rate > 5 || offline_rate > 10
      'healthy'
    end

    def self.determine_overall_health(health_data)
      statuses = [
        health_data[:database_status],
        health_data[:redis_status],
        health_data[:sidekiq_status]
      ]
      
      return 'critical' if statuses.include?('unhealthy')
      return 'warning' if statuses.include?('degraded')
      'healthy'
    end
  end
end