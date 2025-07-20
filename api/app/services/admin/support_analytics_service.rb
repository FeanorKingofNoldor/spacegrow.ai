# app/services/admin/support_analytics_service.rb
module Admin
  class SupportAnalyticsService < ApplicationService
    def support_overview(params)
      begin
        # Focus on actual issues we can detect from system data
        overview = {
          device_problems: analyze_device_issues(params),
          payment_issues: analyze_payment_support_issues(params),
          system_health: analyze_system_health_issues,
          user_activity: analyze_user_activity_issues
        }
        
        success(
          overview: overview,
          priority_issues: identify_priority_issues(overview),
          action_items: generate_support_action_items(overview),
          summary: build_overview_summary(overview)
        )
      rescue => e
        Rails.logger.error "Support overview error: #{e.message}"
        failure("Failed to load support overview: #{e.message}")
      end
    end

    def device_issues_analysis(params)
      begin
        analysis = {
          device_errors: analyze_trending_device_errors,
          connection_issues: analyze_trending_connection_problems,
          geographic_patterns: analyze_device_geographic_issues,
          timeline: build_device_issues_timeline(params)
        }
        
        success(
          device_analysis: analysis,
          affected_users: calculate_affected_users(analysis),
          recommendations: generate_device_recommendations(analysis)
        )
      rescue => e
        Rails.logger.error "Device issues analysis error: #{e.message}"
        failure("Failed to analyze device issues: #{e.message}")
      end
    end

    def payment_issues_analysis(params)
      begin
        analysis = {
          payment_failures: analyze_trending_payment_issues,
          subscription_problems: analyze_subscription_issues,
          revenue_impact: calculate_payment_revenue_impact,
          timeline: build_payment_issues_timeline(params)
        }
        
        success(
          payment_analysis: analysis,
          financial_impact: calculate_financial_impact(analysis),
          recommendations: generate_payment_recommendations(analysis)
        )
      rescue => e
        Rails.logger.error "Payment issues analysis error: #{e.message}"
        failure("Failed to analyze payment issues: #{e.message}")
      end
    end

    def system_insights(period = 'week')
      begin
        date_range = calculate_date_range(period)
        
        insights = {
          device_health_trends: analyze_device_health_trends(date_range),
          payment_health_trends: analyze_payment_health_trends(date_range),
          user_experience_indicators: analyze_user_experience_indicators(date_range)
        }
        
        success(
          period: period,
          insights: insights,
          alerts: generate_system_alerts(insights),
          trend_summary: build_trend_summary(insights)
        )
      rescue => e
        Rails.logger.error "System insights error: #{e.message}"
        failure("Failed to generate system insights: #{e.message}")
      end
    end

    private

    # ===== DEVICE ISSUE ANALYSIS =====
    
    def analyze_device_issues(params)
      offline_devices = Device.where(last_connection: ..1.hour.ago).count
      error_devices = Device.where(status: 'error').count
      never_connected = Device.where(last_connection: nil).where(created_at: ..1.day.ago).count
      
      {
        offline_devices: offline_devices,
        error_devices: error_devices,
        never_connected_devices: never_connected,
        total_problematic: offline_devices + error_devices + never_connected,
        potential_support_load: calculate_device_support_load(offline_devices, error_devices, never_connected),
        device_issue_categories: categorize_current_device_issues
      }
    end

    def analyze_trending_device_errors
      recent_device_errors = Device.where(status: 'error', updated_at: 7.days.ago..)
      previous_week_errors = Device.where(status: 'error', updated_at: 14.days.ago..7.days.ago)
      
      current_count = recent_device_errors.count
      previous_count = previous_week_errors.count
      
      {
        count: current_count,
        trend: calculate_trend(current_count, previous_count),
        impact_level: determine_impact_level(current_count, Device.count),
        common_patterns: analyze_device_error_patterns(recent_device_errors),
        affected_users: recent_device_errors.distinct.count(:user_id),
        by_device_type: recent_device_errors.joins(:device_type).group('device_types.name').count
      }
    end

    def analyze_trending_connection_problems
      offline_devices = Device.where(last_connection: ..1.hour.ago)
      recently_offline = Device.where(last_connection: 1.hour.ago..6.hours.ago)
      
      {
        count: offline_devices.count,
        recently_offline: recently_offline.count,
        trend: calculate_connection_trend,
        impact_level: determine_impact_level(offline_devices.count, Device.count),
        affected_users: offline_devices.distinct.count(:user_id),
        by_device_type: offline_devices.joins(:device_type).group('device_types.name').count
      }
    end

    # ===== PAYMENT ISSUE ANALYSIS =====
    
    def analyze_payment_support_issues(params)
      failed_payments = Order.where(status: 'payment_failed', created_at: 24.hours.ago..)
      past_due_subs = Subscription.where(status: 'past_due')
      
      {
        failed_payments: failed_payments.count,
        past_due_subscriptions: past_due_subs.count,
        affected_revenue: failed_payments.sum(:total),
        affected_users: (failed_payments.pluck(:user_id) + past_due_subs.pluck(:user_id)).uniq.count,
        estimated_support_volume: calculate_payment_support_volume(failed_payments.count, past_due_subs.count),
        payment_issue_trends: analyze_payment_trend(failed_payments)
      }
    end

    def analyze_trending_payment_issues
      recent_failures = Order.where(status: 'payment_failed', created_at: 7.days.ago..)
      previous_failures = Order.where(status: 'payment_failed', created_at: 14.days.ago..7.days.ago)
      
      current_count = recent_failures.count
      previous_count = previous_failures.count
      
      {
        count: current_count,
        trend: calculate_trend(current_count, previous_count),
        impact_level: determine_impact_level(current_count, Order.count),
        affected_revenue: recent_failures.sum(:total),
        affected_users: recent_failures.distinct.count(:user_id),
        failure_reasons: analyze_payment_failure_patterns(recent_failures)
      }
    end

    def analyze_subscription_issues
      past_due = Subscription.where(status: 'past_due').count
      canceled = Subscription.where(status: 'canceled', updated_at: 7.days.ago..).count
      
      {
        past_due_count: past_due,
        recent_cancellations: canceled,
        churn_risk_users: past_due,
        revenue_at_risk: calculate_revenue_at_risk
      }
    end

    # ===== SYSTEM HEALTH ANALYSIS =====
    
    def analyze_system_health_issues
      {
        devices_needing_attention: Device.where(
          'last_connection < ? OR status = ?', 
          1.hour.ago, 'error'
        ).count,
        users_with_device_issues: Device.where(
          'last_connection < ? OR status = ?', 
          1.hour.ago, 'error'
        ).distinct.count(:user_id),
        new_device_setup_failures: Device.where(
          last_connection: nil, 
          created_at: 1.day.ago..
        ).count
      }
    end

    def analyze_user_activity_issues
      inactive_users = User.where(last_sign_in_at: ..30.days.ago).count
      users_with_no_devices = User.left_joins(:devices).where(devices: { id: nil }).count
      
      {
        inactive_users: inactive_users,
        users_without_devices: users_with_no_devices,
        potential_onboarding_issues: users_with_no_devices
      }
    end

    # ===== TREND ANALYSIS HELPERS =====
    
    def calculate_trend(current, previous)
      return 'stable' if previous == 0
      
      change_percent = ((current - previous).to_f / previous * 100).round(1)
      
      case change_percent
      when -Float::INFINITY..-10 then 'decreasing'
      when -10..10 then 'stable'
      else 'increasing'
      end
    end

    def determine_impact_level(count, total)
      percentage = total > 0 ? (count.to_f / total * 100) : 0
      
      case percentage
      when 0..2 then 'low'
      when 2..10 then 'medium'
      else 'high'
      end
    end

    def calculate_connection_trend
      current_offline = Device.where(last_connection: ..1.hour.ago).count
      yesterday_offline = Device.where(last_connection: ..25.hours.ago).where(last_connection: 23.hours.ago..).count
      
      calculate_trend(current_offline, yesterday_offline)
    end

    # ===== PATTERN ANALYSIS =====
    
    def analyze_device_error_patterns(error_devices)
      patterns = []
      
      # Check for common error patterns
      if error_devices.joins(:device_type).where(device_types: { name: 'Environmental Monitor' }).count > 0
        patterns << 'environmental_monitor_issues'
      end
      
      if error_devices.where('created_at > ?', 7.days.ago).count > error_devices.count / 2
        patterns << 'new_device_failures'
      end
      
      patterns.any? ? patterns : ['general_connectivity']
    end

    def analyze_payment_failure_patterns(failed_orders)
      # Analyze failure reasons if available in your Order model
      # This would depend on how you store Stripe failure reasons
      ['card_declined', 'insufficient_funds'] # Simplified
    end

    def categorize_current_device_issues
      categories = []
      
      offline_count = Device.where(last_connection: ..1.hour.ago).count
      error_count = Device.where(status: 'error').count
      never_connected_count = Device.where(last_connection: nil).count
      
      categories << 'connectivity' if offline_count > 0
      categories << 'hardware_errors' if error_count > 0  
      categories << 'setup_issues' if never_connected_count > 0
      
      categories.any? ? categories : ['no_issues']
    end

    # ===== CALCULATION HELPERS =====
    
    def calculate_device_support_load(offline, error, never_connected)
      # Estimate support ticket likelihood
      (offline * 0.1) + (error * 0.8) + (never_connected * 0.3)
    end

    def calculate_payment_support_volume(failed_payments, past_due_subs)
      (failed_payments * 0.6) + (past_due_subs * 0.3)
    end

    def calculate_revenue_at_risk
      Subscription.where(status: 'past_due').joins(:plan).sum('plans.monthly_price')
    end

    def calculate_affected_users(analysis)
      device_affected = analysis[:device_errors][:affected_users] || 0
      payment_affected = analysis[:payment_failures][:affected_users] || 0
      
      device_affected + payment_affected
    end

    def calculate_financial_impact(analysis)
      revenue_lost = analysis[:payment_failures][:affected_revenue] || 0
      revenue_at_risk = analysis[:subscription_problems][:revenue_at_risk] || 0
      
      {
        immediate_loss: revenue_lost,
        potential_loss: revenue_at_risk,
        total_impact: revenue_lost + revenue_at_risk
      }
    end

    # ===== SUMMARY BUILDERS =====
    
    def identify_priority_issues(overview)
      issues = []
      
      device_problems = overview[:device_problems]
      if device_problems[:total_problematic] > 10
        issues << {
          type: 'device_issues',
          severity: device_problems[:total_problematic] > 50 ? 'high' : 'medium',
          count: device_problems[:total_problematic],
          description: "#{device_problems[:total_problematic]} devices need attention"
        }
      end
      
      payment_problems = overview[:payment_issues]
      if payment_problems[:failed_payments] > 5
        issues << {
          type: 'payment_issues', 
          severity: payment_problems[:failed_payments] > 20 ? 'high' : 'medium',
          count: payment_problems[:failed_payments],
          description: "#{payment_problems[:failed_payments]} payment failures need review"
        }
      end
      
      issues
    end

    def generate_support_action_items(overview)
      actions = []
      
      device_problems = overview[:device_problems]
      if device_problems[:error_devices] > 0
        actions << "Investigate #{device_problems[:error_devices]} devices in error state"
      end
      
      if device_problems[:never_connected_devices] > 0
        actions << "Review onboarding for #{device_problems[:never_connected_devices]} devices that never connected"
      end
      
      payment_problems = overview[:payment_issues]  
      if payment_problems[:failed_payments] > 0
        actions << "Follow up on #{payment_problems[:failed_payments]} failed payments"
      end
      
      if payment_problems[:past_due_subscriptions] > 0
        actions << "Contact #{payment_problems[:past_due_subscriptions]} users with past due subscriptions"
      end
      
      actions
    end

    def build_overview_summary(overview)
      total_issues = (overview[:device_problems][:total_problematic] || 0) + 
                    (overview[:payment_issues][:failed_payments] || 0)
      
      {
        total_issues: total_issues,
        primary_concern: determine_primary_concern(overview),
        status: total_issues > 20 ? 'needs_attention' : 'manageable'
      }
    end

    def determine_primary_concern(overview)
      device_issues = overview[:device_problems][:total_problematic] || 0
      payment_issues = overview[:payment_issues][:failed_payments] || 0
      
      if device_issues > payment_issues
        'device_connectivity'
      elsif payment_issues > 0
        'payment_processing'
      else
        'system_healthy'
      end
    end

    # ===== RECOMMENDATION GENERATORS =====
    
    def generate_device_recommendations(analysis)
      recommendations = []
      
      if analysis[:device_errors][:count] > 10
        recommendations << "Implement proactive device monitoring alerts"
      end
      
      if analysis[:connection_issues][:count] > 20
        recommendations << "Review network infrastructure and device connectivity guides"
      end
      
      recommendations
    end

    def generate_payment_recommendations(analysis)
      recommendations = []
      
      if analysis[:payment_failures][:count] > 10
        recommendations << "Review payment failure communications and retry logic"
      end
      
      if analysis[:subscription_problems][:past_due_count] > 5
        recommendations << "Implement automated payment retry and dunning management"
      end
      
      recommendations
    end

    # ===== HELPER METHODS =====
    
    def calculate_date_range(period)
      case period
      when 'day' then 1.day.ago..Time.current
      when 'week' then 1.week.ago..Time.current
      when 'month' then 1.month.ago..Time.current
      else 1.week.ago..Time.current
      end
    end

    def analyze_device_health_trends(date_range)
      {
        error_trend: calculate_trend(
          Device.where(status: 'error', updated_at: date_range).count,
          Device.where(status: 'error', updated_at: (date_range.begin - date_range.size.seconds)..date_range.begin).count
        ),
        connection_trend: calculate_connection_trend
      }
    end

    def analyze_payment_health_trends(date_range)
      current_failures = Order.where(status: 'payment_failed', created_at: date_range).count
      previous_failures = Order.where(status: 'payment_failed', created_at: (date_range.begin - date_range.size.seconds)..date_range.begin).count
      
      {
        payment_failure_trend: calculate_trend(current_failures, previous_failures)
      }
    end

    def analyze_user_experience_indicators(date_range)
      {
        new_user_success_rate: calculate_new_user_success_rate(date_range),
        device_setup_success_rate: calculate_device_setup_success_rate(date_range)
      }
    end

    def calculate_new_user_success_rate(date_range)
      new_users = User.where(created_at: date_range).count
      users_with_devices = User.where(created_at: date_range).joins(:devices).distinct.count
      
      return 100 if new_users == 0
      ((users_with_devices.to_f / new_users) * 100).round(1)
    end

    def calculate_device_setup_success_rate(date_range)
      new_devices = Device.where(created_at: date_range).count
      connected_devices = Device.where(created_at: date_range).where.not(last_connection: nil).count
      
      return 100 if new_devices == 0
      ((connected_devices.to_f / new_devices) * 100).round(1)
    end

    def generate_system_alerts(insights)
      alerts = []
      
      if insights[:device_health_trends][:error_trend] == 'increasing'
        alerts << { type: 'device_errors_increasing', severity: 'warning' }
      end
      
      if insights[:payment_health_trends][:payment_failure_trend] == 'increasing'
        alerts << { type: 'payment_failures_increasing', severity: 'warning' }
      end
      
      alerts
    end

    def build_trend_summary(insights)
      {
        device_health: insights[:device_health_trends][:error_trend],
        payment_health: insights[:payment_health_trends][:payment_failure_trend],
        overall_status: determine_overall_trend_status(insights)
      }
    end

    def determine_overall_trend_status(insights)
      trends = [
        insights[:device_health_trends][:error_trend],
        insights[:payment_health_trends][:payment_failure_trend]
      ]
      
      return 'concerning' if trends.include?('increasing')
      return 'stable' if trends.all? { |t| t == 'stable' }
      'improving'
    end

    def analyze_device_geographic_issues
      # Placeholder for geographic analysis if you track device locations
      { note: "Geographic analysis not implemented - consider adding location tracking" }
    end

    def build_device_issues_timeline(params)
      # Build a simple timeline of device issues over the last week
      (0..6).map do |days_ago|
        date = days_ago.days.ago.to_date
        day_start = date.beginning_of_day
        day_end = date.end_of_day
        
        {
          date: date,
          error_devices: Device.where(status: 'error', updated_at: day_start..day_end).count,
          connection_issues: Device.where(last_connection: day_start..day_end).where('last_connection < ?', day_start + 1.hour).count
        }
      end.reverse
    end

    def build_payment_issues_timeline(params)
      # Build a timeline of payment issues
      (0..6).map do |days_ago|
        date = days_ago.days.ago.to_date
        day_start = date.beginning_of_day
        day_end = date.end_of_day
        
        {
          date: date,
          failed_payments: Order.where(status: 'payment_failed', created_at: day_start..day_end).count,
          failed_amount: Order.where(status: 'payment_failed', created_at: day_start..day_end).sum(:total)
        }
      end.reverse
    end

    def analyze_payment_trend(failed_payments)
      {
        trend: failed_payments.count > 10 ? 'concerning' : 'manageable',
        weekly_average: failed_payments.count / 7.0,
        peak_day: failed_payments.group_by { |o| o.created_at.wday }.max_by { |_, orders| orders.count }&.first
      }
    end
  end
end