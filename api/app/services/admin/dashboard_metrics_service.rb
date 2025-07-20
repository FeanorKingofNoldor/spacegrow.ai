# app/services/admin/dashboard_metrics_service.rb
module Admin
  class DashboardMetricsService < ApplicationService
    def daily_operations_overview
      begin
        metrics = {
          users: user_metrics,
          devices: device_metrics,
          revenue: revenue_metrics,
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
          period: period,
          date_range: {
            start: date_range.begin.iso8601,
            end: date_range.end.iso8601
          },
          user_growth: user_growth_metrics(date_range),
          revenue_trends: revenue_trends(date_range),
          device_adoption: device_adoption_metrics(date_range),
          period_comparison: calculate_period_comparison(period)
        }

        success(
          metrics: metrics,
          generated_at: Time.current
        )
      rescue => e
        Rails.logger.error "Time period metrics error: #{e.message}"
        failure("Failed to load time period metrics: #{e.message}")
      end
    end

    private

    # ===== USER METRICS =====
    
    def user_metrics
      {
        total_users: User.count,
        new_today: User.where(created_at: Date.current.all_day).count,
        active_subscriptions: Subscription.active.count,
        churn_risk: calculate_churn_risk_users,
        conversion_rate: calculate_overall_conversion_rate
      }
    end

    def calculate_churn_risk_users
      # Users whose subscriptions expire soon or have payment issues
      at_risk_count = 0
      
      # Subscriptions expiring in next 7 days
      at_risk_count += Subscription.where(
        current_period_end: Date.current..7.days.from_now,
        status: 'active'
      ).count
      
      # Users with recent payment failures
      failed_orders = Order.where(
        created_at: 7.days.ago..Time.current,
        status: 'failed'
      ).distinct.count(:user_id)
      
      at_risk_count + failed_orders
    end

    def calculate_overall_conversion_rate
      # Users who signed up and got a subscription within 30 days
      new_users = User.where(created_at: 30.days.ago..Time.current).count
      return 0 if new_users == 0
      
      converted_users = User.joins(:subscription)
                           .where(created_at: 30.days.ago..Time.current)
                           .where(subscriptions: { created_at: 30.days.ago..Time.current })
                           .count
                           
      ((converted_users.to_f / new_users) * 100).round(1)
    end

    # ===== DEVICE METRICS =====
    
    def device_metrics
      {
        total_devices: Device.count,
        active_devices: Device.where(status: 'active').count,
        offline_devices: Device.where(last_connection: ..1.hour.ago).count,
        new_today: Device.where(created_at: Date.current.all_day).count,
        error_devices: Device.where(status: 'error').count,
        fleet_utilization: calculate_fleet_utilization,
        never_connected: Device.where(last_connection: nil).count
      }
    end

    def device_health_issues
      Device.where(last_connection: ..1.hour.ago).count
    end

    def calculate_fleet_utilization
      # Calculate percentage of device slots in use
      total_slots = User.joins(:subscription, subscription: :plan)
                       .sum('plans.device_limit')
      used_slots = Device.where(status: 'active').count
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
      Subscription.where(status: 'active').joins(:plan).sum('plans.monthly_price')
    end

    def average_order_value
      completed_orders = Order.where(status: 'completed', created_at: 30.days.ago..Time.current)
      return 0 if completed_orders.empty?
      (completed_orders.sum(:total) / completed_orders.count).round(2)
    end

    def revenue_growth_rate
      current_month_revenue = Order.where(
        created_at: Date.current.beginning_of_month..Date.current.end_of_month,
        status: 'completed'
      ).sum(:total)
      
      last_month_revenue = Order.where(
        created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month,
        status: 'completed'
      ).sum(:total)
      
      return 0 if last_month_revenue == 0
      (((current_month_revenue - last_month_revenue) / last_month_revenue.to_f) * 100).round(1)
    end

    # ===== ALERT SYSTEM =====
    
    def alert_summary
      {
        critical: count_critical_alerts,
        warning: count_warning_alerts,
        info: count_info_alerts
      }
    end

    def count_critical_alerts
      alerts = 0
      
      # Devices offline for more than 24 hours
      alerts += 1 if Device.where(last_connection: ..24.hours.ago).count > 20
      
      # High payment failure rate
      alerts += 1 if recent_payment_failures > 10
      
      # Many subscription cancellations
      alerts += 1 if recent_cancellations > 5
      
      alerts
    end

    def count_warning_alerts
      alerts = 0
      
      # Devices offline for more than 1 hour
      alerts += 1 if Device.where(last_connection: ..1.hour.ago).count > 10
      
      # Low conversion rate
      alerts += 1 if calculate_overall_conversion_rate < 10
      
      # High churn risk
      alerts += 1 if calculate_churn_risk_users > 20
      
      alerts
    end

    def count_info_alerts
      alerts = 0
      
      # New user milestones
      new_today = User.where(created_at: Date.current.all_day).count
      alerts += 1 if new_today > 10
      
      # Revenue milestones
      daily_revenue = daily_revenue_calculation
      alerts += 1 if daily_revenue > 1000
      
      alerts
    end

    # ===== PAYMENT AND SUBSCRIPTION ALERTS =====
    
    def recent_payment_failures
      Order.where(
        created_at: 24.hours.ago..Time.current,
        status: 'failed'
      ).count
    end

    def recent_cancellations
      Subscription.where(
        updated_at: 24.hours.ago..Time.current,
        status: 'cancelled'
      ).count
    end

    def payment_failure_alert(count)
      {
        type: 'payment_failures',
        severity: 'critical',
        count: count,
        message: "#{count} payment failures in the last 24 hours",
        action_required: true
      }
    end

    def offline_devices_alert(count)
      {
        type: 'offline_devices',
        severity: 'warning',
        count: count,
        message: "#{count} devices appear to be offline",
        action_required: false
      }
    end

    def cancellation_alert(count)
      {
        type: 'subscription_cancellations',
        severity: 'warning',
        count: count,
        message: "#{count} subscription cancellations in the last 24 hours",
        action_required: true
      }
    end

    # ===== SYSTEM HEALTH =====
    
    def system_health_check
      {
        database_status: check_database_health,
        redis_status: check_redis_health,
        uptime: calculate_system_uptime,
        error_rate: calculate_recent_error_rate,
        response_time: calculate_average_response_time
      }
    end

    def check_database_health
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        'healthy'
      rescue
        'unhealthy'
      end
    end

    def check_redis_health
      begin
        Rails.cache.redis.ping
        'healthy'
      rescue
        'unhealthy'
      end
    end

    def calculate_system_uptime
      # Based on successful requests vs errors in last 24h
      # This is a simplified calculation - you might want to integrate with real monitoring
      total_requests = estimate_daily_requests
      error_requests = calculate_recent_error_count
      
      return "99.9%" if total_requests == 0
      
      uptime_percentage = ((total_requests - error_requests).to_f / total_requests * 100).round(1)
      "#{uptime_percentage}%"
    end

    def calculate_recent_error_rate
      # Simplified error rate calculation based on failed orders and device connection issues
      total_operations = estimate_daily_operations
      error_operations = recent_payment_failures + device_health_issues
      
      return 0 if total_operations == 0
      ((error_operations.to_f / total_operations) * 100).round(2)
    end

    def calculate_average_response_time
      # Simplified response time - in a real system you'd integrate with APM tools
      "120ms"
    end

    # ===== TIME PERIOD ANALYTICS =====
    
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
        one_time_revenue: calculate_one_time_revenue(date_range),
        average_order_value: calculate_period_avg_order_value(date_range)
      }
    end

    def device_adoption_metrics(date_range)
      {
        devices_registered: Device.where(created_at: date_range).count,
        devices_activated: Device.where(created_at: date_range, status: 'active').count,
        activation_rate: calculate_device_activation_rate(date_range)
      }
    end

    # ===== CALCULATION HELPERS =====
    
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

    def calculate_period_avg_order_value(date_range)
      orders = Order.where(created_at: date_range, status: 'completed')
      return 0 if orders.empty?
      (orders.sum(:total) / orders.count).round(2)
    end

    # ===== SUMMARY AND UTILITIES =====
    
    def generate_daily_summary(metrics)
      {
        users_added: metrics[:users][:new_today],
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

    def calculate_period_comparison(period)
      current_range = calculate_date_range(period)
      previous_range = calculate_previous_period_range(period)
      
      {
        current_period: {
          users: User.where(created_at: current_range).count,
          revenue: Order.where(created_at: current_range, status: 'completed').sum(:total),
          devices: Device.where(created_at: current_range).count
        },
        previous_period: {
          users: User.where(created_at: previous_range).count,
          revenue: Order.where(created_at: previous_range, status: 'completed').sum(:total),
          devices: Device.where(created_at: previous_range).count
        }
      }
    end

    def calculate_previous_period_range(period)
      case period
      when 'today'
        1.day.ago.all_day
      when 'week'
        2.weeks.ago..1.week.ago
      when 'month'
        2.months.ago..1.month.ago
      when 'quarter'
        6.months.ago..3.months.ago
      else
        1.day.ago.all_day
      end
    end

    # ===== ESTIMATION HELPERS =====
    
    def estimate_daily_requests
      # Rough estimate based on users and devices
      active_users = User.joins(:subscription).where(subscriptions: { status: 'active' }).count
      active_devices = Device.where(status: 'active').count
      
      # Assume each user makes ~10 requests/day, each device makes ~50 data points/day
      (active_users * 10) + (active_devices * 50)
    end

    def estimate_daily_operations
      # Total estimated operations including user actions and device communications
      estimate_daily_requests + device_health_issues + recent_payment_failures
    end

    def calculate_recent_error_count
      # Count various types of recent errors
      recent_payment_failures + device_health_issues + (Device.where(status: 'error').count * 5)
    end
  end
end