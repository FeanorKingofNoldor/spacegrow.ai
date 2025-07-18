# app/services/admin/dashboard_metrics_service.rb
module Admin
  class DashboardMetricsService < ApplicationService
    def daily_operations_overview
      begin
        metrics = {
          users: user_metrics,
          devices: device_metrics,
          revenue: revenue_metrics,
          support: support_metrics,
          alerts: alert_summary,
          system_health: system_health_check
        }

        success(
          metrics: metrics,
          last_updated: Time.current,
          summary: generate_daily_summary(metrics)
        )
      rescue => e
        Rails.logger.error "Dashboard metrics error: #{e.message}"
        failure("Failed to load dashboard metrics: #{e.message}")
      end
    end

    def critical_alerts
      begin
        alerts = []
        
        # Payment failures in last 24h
        payment_failures = recent_payment_failures
        alerts << payment_failure_alert(payment_failures) if payment_failures > 5

        # Offline devices
        offline_devices = device_health_issues
        alerts << offline_devices_alert(offline_devices) if offline_devices > 10

        # High error rates
        error_rate = system_error_rate
        alerts << error_rate_alert(error_rate) if error_rate > 5

        # Subscription cancellations
        cancellations = recent_cancellations
        alerts << cancellation_alert(cancellations) if cancellations > 3

        success(
          alerts: alerts,
          total_alerts: alerts.count,
          severity_breakdown: calculate_severity_breakdown(alerts)
        )
      rescue => e
        Rails.logger.error "Critical alerts error: #{e.message}"
        failure("Failed to load critical alerts: #{e.message}")
      end
    end

    def time_period_metrics(period)
      begin
        date_range = calculate_date_range(period)
        
        metrics = {
          user_growth: user_growth_metrics(date_range),
          revenue_trends: revenue_trends(date_range),
          device_adoption: device_adoption_metrics(date_range),
          support_volume: support_volume_metrics(date_range)
        }

        success(
          period: period,
          date_range: date_range,
          metrics: metrics,
          comparisons: calculate_period_comparisons(metrics, period)
        )
      rescue => e
        Rails.logger.error "Time period metrics error: #{e.message}"
        failure("Failed to load #{period} metrics: #{e.message}")
      end
    end

    private

    # ===== USER METRICS =====
    
    def user_metrics
      {
        total_users: User.count,
        new_today: User.where(created_at: Date.current.all_day).count,
        active_subscriptions: Subscription.active.count,
        churn_risk: users_at_churn_risk,
        top_plans: subscription_distribution
      }
    end

    def users_at_churn_risk
      # Users with failed payments or long inactivity
      User.joins(:subscription)
          .where(subscriptions: { status: 'past_due' })
          .or(User.where(last_sign_in_at: ..1.month.ago))
          .count
    end

    def subscription_distribution
      Plan.joins(:subscriptions)
          .where(subscriptions: { status: 'active' })
          .group(:name)
          .count
    end

    # ===== DEVICE METRICS =====
    
    def device_metrics
      {
        total_devices: Device.count,
        active_devices: Device.active.count,
        offline_devices: Device.where(last_connection: ..1.hour.ago).count,
        new_today: Device.where(created_at: Date.current.all_day).count,
        error_devices: Device.where(status: 'error').count,
        fleet_utilization: calculate_fleet_utilization
      }
    end

    def device_health_issues
      Device.where(last_connection: ..1.hour.ago).count
    end

    def calculate_fleet_utilization
      total_slots = User.joins(:subscription).sum { |u| u.device_limit }
      used_slots = Device.active.count
      return 0 if total_slots == 0
      ((used_slots.to_f / total_slots) * 100).round(1)
    end

    # ===== REVENUE METRICS =====
    
    def revenue_metrics
      {
        daily_revenue: daily_revenue_calculation,
        monthly_recurring_revenue: monthly_recurring_revenue,
        total_revenue_today: Order.where(created_at: Date.current.all_day, status: 'completed').sum(:total),
        avg_order_value: average_order_value,
        revenue_growth: revenue_growth_rate
      }
    end

    def daily_revenue_calculation
      Order.where(created_at: Date.current.all_day, status: 'completed').sum(:total)
    end

    def monthly_recurring_revenue
      Subscription.active.joins(:plan).sum('plans.monthly_price')
    end

    def average_order_value
      completed_orders = Order.where(status: 'completed', created_at: 30.days.ago..Time.current)
      return 0 if completed_orders.empty?
      (completed_orders.sum(:total) / completed_orders.count).round(2)
    end

    def revenue_growth_rate
      current_month = monthly_recurring_revenue
      last_month = Subscription.where(created_at: 1.month.ago..Date.current.beginning_of_month)
                              .joins(:plan).sum('plans.monthly_price')
      return 0 if last_month == 0
      (((current_month - last_month).to_f / last_month) * 100).round(1)
    end

    # ===== SUPPORT METRICS =====
    
    def support_metrics
      {
        open_tickets: support_requests_count('open'),
        resolved_today: support_requests_resolved_today,
        avg_response_time: average_response_time,
        satisfaction_score: customer_satisfaction_score
      }
    end

    def support_requests_count(status)
      # Placeholder - implement based on your support system
      # This might be from a SupportRequest model or external service
      0
    end

    def support_requests_resolved_today
      # Placeholder - implement based on your support system
      0
    end

    def average_response_time
      # Placeholder - calculate from your support system
      "2.5 hours"
    end

    def customer_satisfaction_score
      # Placeholder - implement based on your feedback system
      4.2
    end

    # ===== ALERT CALCULATIONS =====
    
    def alert_summary
      {
        critical: count_critical_alerts,
        warning: count_warning_alerts,
        info: count_info_alerts
      }
    end

    def count_critical_alerts
      alerts = 0
      alerts += 1 if recent_payment_failures > 5
      alerts += 1 if device_health_issues > 10
      alerts += 1 if system_error_rate > 5
      alerts
    end

    def count_warning_alerts
      alerts = 0
      alerts += 1 if users_at_churn_risk > 5
      alerts += 1 if recent_cancellations > 3
      alerts
    end

    def count_info_alerts
      # Info alerts for things like system updates, maintenance windows, etc.
      1 # Placeholder
    end

    def recent_payment_failures
      Order.where(status: 'payment_failed', created_at: 24.hours.ago..Time.current).count
    end

    def recent_cancellations
      Subscription.where(status: 'canceled', updated_at: 24.hours.ago..Time.current).count
    end

    def system_error_rate
      # Calculate error rate from logs or monitoring service
      # Placeholder implementation
      2.1
    end

    # ===== SYSTEM HEALTH =====
    
    def system_health_check
      {
        database_status: check_database_health,
        redis_status: check_redis_health,
        sidekiq_status: check_sidekiq_health,
        response_time: check_response_time
      }
    end

    def check_database_health
      User.connection.execute("SELECT 1")
      "healthy"
    rescue
      "unhealthy"
    end

    def check_redis_health
      Rails.cache.write("health_check", "ok")
      Rails.cache.read("health_check") == "ok" ? "healthy" : "unhealthy"
    rescue
      "unhealthy"
    end

    def check_sidekiq_health
      Sidekiq::Queue.new.size < 100 ? "healthy" : "overloaded"
    rescue
      "unhealthy"
    end

    def check_response_time
      # Placeholder - implement with your monitoring
      "145ms"
    end

    # ===== ALERT BUILDERS =====
    
    def payment_failure_alert(count)
      {
        type: 'critical',
        title: 'High Payment Failure Rate',
        message: "#{count} payment failures in the last 24 hours",
        action_url: '/admin/orders?status=payment_failed',
        severity: 'critical'
      }
    end

    def offline_devices_alert(count)
      {
        type: 'warning',
        title: 'Devices Offline',
        message: "#{count} devices haven't connected in the last hour",
        action_url: '/admin/devices?status=offline',
        severity: 'warning'
      }
    end

    def error_rate_alert(rate)
      {
        type: 'critical',
        title: 'High Error Rate',
        message: "System error rate at #{rate}%",
        action_url: '/admin/system/logs',
        severity: 'critical'
      }
    end

    def cancellation_alert(count)
      {
        type: 'warning',
        title: 'Subscription Cancellations',
        message: "#{count} subscription cancellations in 24 hours",
        action_url: '/admin/subscriptions?status=canceled',
        severity: 'warning'
      }
    end

    # ===== HELPER METHODS =====
    
    def generate_daily_summary(metrics)
      {
        users_growth: metrics[:users][:new_today],
        revenue_today: metrics[:revenue][:total_revenue_today],
        devices_added: metrics[:devices][:new_today],
        health_status: overall_health_status(metrics)
      }
    end

    def overall_health_status(metrics)
      critical_alerts = metrics[:alerts][:critical]
      return 'critical' if critical_alerts > 0
      
      warning_alerts = metrics[:alerts][:warning] 
      return 'warning' if warning_alerts > 2
      
      'healthy'
    end

    def calculate_severity_breakdown(alerts)
      alerts.group_by { |alert| alert[:severity] }.transform_values(&:count)
    end

    def calculate_date_range(period)
      case period
      when 'today'
        Date.current.all_day
      when 'week'
        1.week.ago..Time.current
      when 'month' 
        1.month.ago..Time.current
      when 'quarter'
        3.months.ago..Time.current
      else
        Date.current.all_day
      end
    end

    def user_growth_metrics(date_range)
      {
        new_users: User.where(created_at: date_range).count,
        activated_users: User.joins(:subscription).where(created_at: date_range).count,
        conversion_rate: calculate_conversion_rate(date_range)
      }
    end

    def revenue_trends(date_range)
      {
        total_revenue: Order.where(created_at: date_range, status: 'completed').sum(:total),
        subscription_revenue: calculate_subscription_revenue(date_range),
        one_time_revenue: calculate_one_time_revenue(date_range)
      }
    end

    def device_adoption_metrics(date_range)
      {
        devices_registered: Device.where(created_at: date_range).count,
        devices_activated: Device.where(created_at: date_range, status: 'active').count,
        activation_rate: calculate_device_activation_rate(date_range)
      }
    end

    def support_volume_metrics(date_range)
      {
        tickets_created: 0, # Implement based on your support system
        tickets_resolved: 0,
        avg_resolution_time: "0 hours"
      }
    end

    def calculate_conversion_rate(date_range)
      new_users = User.where(created_at: date_range).count
      activated_users = User.joins(:subscription).where(created_at: date_range).count
      return 0 if new_users == 0
      ((activated_users.to_f / new_users) * 100).round(1)
    end

    def calculate_subscription_revenue(date_range)
      Subscription.where(created_at: date_range).joins(:plan).sum('plans.monthly_price')
    end

    def calculate_one_time_revenue(date_range)
      Order.where(created_at: date_range, status: 'completed').sum(:total)
    end

    def calculate_device_activation_rate(date_range)
      registered = Device.where(created_at: date_range).count
      activated = Device.where(created_at: date_range, status: 'active').count
      return 0 if registered == 0
      ((activated.to_f / registered) * 100).round(1)
    end

    def calculate_period_comparisons(metrics, period)
      # Compare with previous period
      # Implementation depends on specific needs
      {}
    end
  end
end