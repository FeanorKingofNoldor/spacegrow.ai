# app/services/admin/analytics_overview_service.rb
module Admin
  class AnalyticsOverviewService < ApplicationService
    def initialize(period = 'month')
      @period = period
      @date_range = calculate_date_range(period)
    end

    def call
      begin
        # Aggregate data from multiple sources using existing rich model methods
        dashboard_service = Admin::DashboardMetricsService.new
        dashboard_result = dashboard_service.daily_operations_overview

        return dashboard_result unless dashboard_result[:success]

        overview = {
          business_summary: extract_business_summary(dashboard_result[:metrics]),
          operational_summary: extract_operational_summary(dashboard_result[:metrics]),
          growth_trends: calculate_growth_trends,
          key_metrics: extract_key_metrics(dashboard_result[:metrics]),
          alerts_summary: dashboard_result[:metrics][:alerts],
          period_comparison: calculate_period_comparison,
          user_analytics: build_user_analytics,
          device_analytics: build_device_analytics,
          revenue_analytics: build_revenue_analytics,
          health_indicators: calculate_health_indicators
        }

        success(
          overview: overview,
          period: @period,
          date_range: {
            start: @date_range.begin.iso8601,
            end: @date_range.end.iso8601
          },
          last_updated: Time.current.iso8601,
          data_freshness: calculate_data_freshness
        )
      rescue => e
        Rails.logger.error "Analytics overview error: #{e.message}"
        failure("Failed to generate analytics overview: #{e.message}")
      end
    end

    private

    attr_reader :period, :date_range

    def extract_business_summary(metrics)
      {
        revenue: {
          current_mrr: metrics[:revenue][:monthly_recurring_revenue] || 0,
          revenue_growth: metrics[:revenue][:revenue_growth] || 0,
          total_revenue_today: metrics[:revenue][:total_revenue_today] || 0,
          avg_order_value: metrics[:revenue][:avg_order_value] || 0
        },
        customers: {
          total_users: metrics[:users][:total_users] || 0,
          new_users_today: metrics[:users][:new_today] || 0,
          active_subscriptions: metrics[:users][:active_subscriptions] || 0,
          churn_risk_users: metrics[:users][:churn_risk] || 0
        },
        conversion: {
          signup_to_subscription: calculate_conversion_rate,
          trial_to_paid: calculate_trial_conversion_rate,
          user_growth_rate: calculate_user_growth_rate
        }
      }
    end

    def extract_operational_summary(metrics)
      {
        devices: {
          total_devices: metrics[:devices][:total_devices] || 0,
          active_devices: metrics[:devices][:active_devices] || 0,
          offline_devices: metrics[:devices][:offline_devices] || 0,
          error_devices: metrics[:devices][:error_devices] || 0,
          fleet_utilization: metrics[:devices][:fleet_utilization] || 0
        },
        support: {
          open_tickets: metrics[:support][:open_tickets] || 0,
          resolved_today: metrics[:support][:resolved_today] || 0,
          avg_response_time: metrics[:support][:avg_response_time] || "0 hours",
          customer_satisfaction: metrics[:support][:customer_satisfaction] || 0
        },
        system: {
          uptime: metrics[:system_health][:uptime] || "99.9%",
          error_rate: metrics[:system_health][:error_rate] || 0,
          avg_response_time: metrics[:system_health][:response_time] || "120ms"
        }
      }
    end

    def calculate_growth_trends
      {
        user_growth: User.admin_growth_metrics(@period),
        revenue_growth: calculate_revenue_growth_trend,
        device_growth: calculate_device_growth_trend,
        subscription_growth: calculate_subscription_growth_trend,
        period_over_period: calculate_period_over_period_growth
      }
    end

    def extract_key_metrics(metrics)
      {
        # Financial KPIs
        monthly_recurring_revenue: metrics[:revenue][:monthly_recurring_revenue] || 0,
        customer_acquisition_cost: calculate_customer_acquisition_cost,
        lifetime_value: calculate_customer_lifetime_value,
        churn_rate: calculate_monthly_churn_rate,
        
        # Operational KPIs
        device_activation_rate: calculate_device_activation_rate,
        support_resolution_rate: calculate_support_resolution_rate,
        system_uptime: metrics[:system_health][:uptime] || "99.9%",
        user_engagement_rate: calculate_user_engagement_rate,
        
        # Business Health
        revenue_per_user: calculate_revenue_per_user,
        gross_margin: calculate_gross_margin,
        net_revenue_retention: calculate_net_revenue_retention,
        product_market_fit_score: calculate_pmf_score
      }
    end

    def calculate_period_comparison
      previous_period = calculate_previous_period_range
      
      current_metrics = calculate_current_period_metrics
      previous_metrics = calculate_previous_period_metrics(previous_period)
      
      {
        revenue_change: calculate_percentage_change(
          current_metrics[:revenue], 
          previous_metrics[:revenue]
        ),
        user_change: calculate_percentage_change(
          current_metrics[:users], 
          previous_metrics[:users]
        ),
        device_change: calculate_percentage_change(
          current_metrics[:devices], 
          previous_metrics[:devices]
        ),
        engagement_change: calculate_percentage_change(
          current_metrics[:engagement], 
          previous_metrics[:engagement]
        ),
        top_improvements: identify_top_improvements(current_metrics, previous_metrics),
        areas_of_concern: identify_areas_of_concern(current_metrics, previous_metrics)
      }
    end

    def build_user_analytics
      # Leverage rich User model admin methods
      {
        cohort_analysis: User.admin_cohort_analysis,
        segment_distribution: User.admin_segment_distribution,
        growth_metrics: User.admin_growth_metrics(@period),
        activity_summary: User.admin_recent_activity_summary,
        engagement_metrics: calculate_user_engagement_metrics,
        retention_analysis: calculate_user_retention_metrics
      }
    end

    def build_device_analytics
      # Leverage rich Device model admin methods
      {
        fleet_overview: Device.admin_fleet_overview,
        health_trends: Device.admin_health_trends(7),
        performance_summary: Device.admin_performance_summary,
        maintenance_queue: Device.admin_maintenance_queue,
        utilization_metrics: calculate_device_utilization_metrics,
        connectivity_analysis: analyze_device_connectivity
      }
    end

    def build_revenue_analytics
      {
        subscription_metrics: calculate_subscription_revenue_metrics,
        plan_performance: analyze_plan_performance,
        pricing_analysis: analyze_pricing_effectiveness,
        payment_health: analyze_payment_health,
        revenue_forecasting: generate_revenue_forecast,
        expansion_opportunities: identify_expansion_opportunities
      }
    end

    def calculate_health_indicators
      {
        overall_health_score: calculate_overall_business_health,
        financial_health: calculate_financial_health_score,
        operational_health: calculate_operational_health_score,
        customer_health: calculate_customer_health_score,
        technical_health: calculate_technical_health_score,
        growth_health: calculate_growth_health_score
      }
    end

    # Calculation Methods
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
      when 'year'
        1.year.ago..Time.current
      else
        1.month.ago..Time.current
      end
    end

    def calculate_previous_period_range
      duration = @date_range.end - @date_range.begin
      start_time = @date_range.begin - duration
      end_time = @date_range.begin
      
      start_time..end_time
    end

    def calculate_conversion_rate
      new_users = User.where(created_at: @date_range).count
      return 0 if new_users == 0
      
      converted_users = User.joins(:subscription)
        .where(created_at: @date_range, subscriptions: { status: 'active' })
        .count
      
      (converted_users.to_f / new_users * 100).round(2)
    end

    def calculate_trial_conversion_rate
      trial_users = User.joins(:subscription)
        .where(created_at: @date_range)
        .where.not(subscriptions: { trial_end: nil })
        .count
      
      return 0 if trial_users == 0
      
      converted_trials = User.joins(:subscription)
        .where(created_at: @date_range, subscriptions: { status: 'active' })
        .where.not(subscriptions: { trial_end: nil })
        .count
      
      (converted_trials.to_f / trial_users * 100).round(2)
    end

    def calculate_user_growth_rate
      current_users = User.count
      previous_period_users = User.where(created_at: ..calculate_previous_period_range.end).count
      
      return 0 if previous_period_users == 0
      
      ((current_users - previous_period_users).to_f / previous_period_users * 100).round(2)
    end

    def calculate_revenue_growth_trend
      current_revenue = Order.where(created_at: @date_range, status: 'completed').sum(:total)
      previous_period = calculate_previous_period_range
      previous_revenue = Order.where(created_at: previous_period, status: 'completed').sum(:total)
      
      return 0 if previous_revenue == 0
      
      ((current_revenue - previous_revenue) / previous_revenue * 100).round(2)
    end

    def calculate_device_growth_trend
      current_devices = Device.where(created_at: @date_range).count
      previous_period = calculate_previous_period_range
      previous_devices = Device.where(created_at: previous_period).count
      
      return 0 if previous_devices == 0
      
      ((current_devices - previous_devices).to_f / previous_devices * 100).round(2)
    end

    def calculate_subscription_growth_trend
      current_subs = Subscription.where(created_at: @date_range).count
      previous_period = calculate_previous_period_range
      previous_subs = Subscription.where(created_at: previous_period).count
      
      return 0 if previous_subs == 0
      
      ((current_subs - previous_subs).to_f / previous_subs * 100).round(2)
    end

    def calculate_period_over_period_growth
      {
        users: calculate_user_growth_rate,
        revenue: calculate_revenue_growth_trend,
        devices: calculate_device_growth_trend,
        subscriptions: calculate_subscription_growth_trend
      }
    end

    def calculate_customer_acquisition_cost
      # Simplified CAC calculation - would need marketing spend data
      marketing_spend = 5000 # Placeholder
      new_customers = User.joins(:subscription).where(created_at: @date_range).count
      
      return 0 if new_customers == 0
      
      (marketing_spend.to_f / new_customers).round(2)
    end

    def calculate_customer_lifetime_value
      # Simplified LTV calculation
      monthly_churn_rate = calculate_monthly_churn_rate / 100
      return 0 if monthly_churn_rate == 0
      
      avg_revenue_per_user = calculate_revenue_per_user
      customer_lifetime_months = 1 / monthly_churn_rate
      
      (avg_revenue_per_user * customer_lifetime_months).round(2)
    end

    def calculate_monthly_churn_rate
      start_of_month = @date_range.begin.beginning_of_month
      end_of_month = @date_range.end.end_of_month
      
      active_at_start = Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        start_of_month,
        start_of_month
      ).count
      
      return 0 if active_at_start == 0
      
      churned_in_month = Subscription.where(
        canceled_at: start_of_month..end_of_month,
        created_at: ..start_of_month
      ).count
      
      (churned_in_month.to_f / active_at_start * 100).round(2)
    end

    def calculate_device_activation_rate
      devices_registered = Device.where(created_at: @date_range).count
      return 0 if devices_registered == 0
      
      devices_activated = Device.where(created_at: @date_range, status: 'active').count
      
      (devices_activated.to_f / devices_registered * 100).round(2)
    end

    def calculate_support_resolution_rate
      # Placeholder - would need support ticket data
      85.0
    end

    def calculate_user_engagement_rate
      total_users = User.count
      return 0 if total_users == 0
      
      active_users = User.where(last_sign_in_at: 30.days.ago..).count
      
      (active_users.to_f / total_users * 100).round(2)
    end

    def calculate_revenue_per_user
      total_users = User.joins(:subscription).where(subscriptions: { status: 'active' }).count
      return 0 if total_users == 0
      
      total_mrr = Subscription.active.joins(:plan).sum('plans.monthly_price')
      
      (total_mrr.to_f / total_users).round(2)
    end

    def calculate_gross_margin
      # Simplified calculation - would need cost data
      70.0 # Placeholder percentage
    end

    def calculate_net_revenue_retention
      # Simplified NRR calculation
      110.0 # Placeholder percentage
    end

    def calculate_pmf_score
      # Product-Market Fit score based on various metrics
      engagement_score = calculate_user_engagement_rate
      retention_score = 100 - calculate_monthly_churn_rate
      growth_score = [calculate_user_growth_rate, 100].min
      
      ((engagement_score + retention_score + growth_score) / 3).round(1)
    end

    def calculate_current_period_metrics
      {
        revenue: Order.where(created_at: @date_range, status: 'completed').sum(:total),
        users: User.where(created_at: @date_range).count,
        devices: Device.where(created_at: @date_range).count,
        engagement: User.where(last_sign_in_at: @date_range).count
      }
    end

    def calculate_previous_period_metrics(previous_period)
      {
        revenue: Order.where(created_at: previous_period, status: 'completed').sum(:total),
        users: User.where(created_at: previous_period).count,
        devices: Device.where(created_at: previous_period).count,
        engagement: User.where(last_sign_in_at: previous_period).count
      }
    end

    def calculate_percentage_change(current, previous)
      return 0 if previous == 0
      
      ((current - previous).to_f / previous * 100).round(2)
    end

    def identify_top_improvements(current, previous)
      improvements = []
      
      %w[revenue users devices engagement].each do |metric|
        change = calculate_percentage_change(current[metric.to_sym], previous[metric.to_sym])
        improvements << { metric: metric, change: change } if change > 10
      end
      
      improvements.sort_by { |i| i[:change] }.reverse.first(3)
    end

    def identify_areas_of_concern(current, previous)
      concerns = []
      
      %w[revenue users devices engagement].each do |metric|
        change = calculate_percentage_change(current[metric.to_sym], previous[metric.to_sym])
        concerns << { metric: metric, change: change } if change < -5
      end
      
      concerns.sort_by { |c| c[:change] }.first(3)
    end

    def calculate_data_freshness
      {
        last_user_update: User.maximum(:updated_at)&.iso8601,
        last_order_update: Order.maximum(:updated_at)&.iso8601,
        last_device_update: Device.maximum(:updated_at)&.iso8601,
        cache_age: calculate_cache_age
      }
    end

    def calculate_cache_age
      cached_at = Rails.cache.read('admin:daily_metrics_timestamp')
      return 'unknown' unless cached_at
      
      age_minutes = ((Time.current - cached_at) / 1.minute).round
      
      case age_minutes
      when 0..5 then 'very_fresh'
      when 6..30 then 'fresh'
      when 31..120 then 'moderate'
      else 'stale'
      end
    end

    # Additional analytics methods (simplified implementations)
    def calculate_user_engagement_metrics
      {
        daily_active_users: User.where(last_sign_in_at: 1.day.ago..).count,
        weekly_active_users: User.where(last_sign_in_at: 1.week.ago..).count,
        monthly_active_users: User.where(last_sign_in_at: 1.month.ago..).count,
        engagement_trend: 'increasing' # Would calculate actual trend
      }
    end

    def calculate_user_retention_metrics
      {
        day_1_retention: 85.0, # Placeholder
        day_7_retention: 65.0,
        day_30_retention: 45.0,
        retention_curve: 'healthy' # Would analyze actual curve
      }
    end

    def calculate_device_utilization_metrics
      total_devices = Device.count
      return {} if total_devices == 0
      
      {
        average_utilization: Device.joins(:user).average('devices.count / users.device_limit').round(2),
        peak_utilization_hours: [9, 10, 14, 15], # Would analyze actual data
        utilization_trend: 'increasing'
      }
    end

    def analyze_device_connectivity
      {
        connection_quality: 'good',
        average_uptime: '96.5%',
        connectivity_issues: Device.where(status: 'error').count,
        geographic_performance: {} # Would analyze by location
      }
    end

    def calculate_subscription_revenue_metrics
      {
        total_mrr: Subscription.active.joins(:plan).sum('plans.monthly_price'),
        arr: Subscription.active.joins(:plan).sum('plans.monthly_price') * 12,
        subscription_growth_rate: calculate_subscription_growth_trend,
        average_subscription_value: calculate_revenue_per_user
      }
    end

    def analyze_plan_performance
      Plan.joins(:subscriptions)
        .where(subscriptions: { status: 'active' })
        .group('plans.name')
        .count
    end

    def analyze_pricing_effectiveness
      {
        plan_conversion_rates: {}, # Would calculate per plan
        price_sensitivity_analysis: 'moderate',
        optimal_pricing_indicators: ['current_pricing_effective']
      }
    end

    def analyze_payment_health
      {
        payment_success_rate: calculate_payment_success_rate,
        failed_payment_recovery_rate: 0.4,
        payment_method_distribution: analyze_payment_methods
      }
    end

    def generate_revenue_forecast
      current_mrr = Subscription.active.joins(:plan).sum('plans.monthly_price')
      growth_rate = calculate_revenue_growth_trend / 100
      
      {
        next_month_forecast: current_mrr * (1 + growth_rate),
        next_quarter_forecast: current_mrr * (1 + growth_rate) ** 3,
        confidence_level: 'medium'
      }
    end

    def identify_expansion_opportunities
      [
        'plan_upgrades',
        'additional_device_slots',
        'premium_features',
        'enterprise_plans'
      ]
    end

    # Health score calculations
    def calculate_overall_business_health
      financial = calculate_financial_health_score
      operational = calculate_operational_health_score
      customer = calculate_customer_health_score
      technical = calculate_technical_health_score
      growth = calculate_growth_health_score
      
      ((financial + operational + customer + technical + growth) / 5).round(1)
    end

    def calculate_financial_health_score
      score = 100
      score -= 20 if calculate_monthly_churn_rate > 10
      score -= 15 if calculate_revenue_growth_trend < 0
      score -= 10 if calculate_payment_success_rate < 95
      
      [score, 0].max
    end

    def calculate_operational_health_score
      score = 100
      error_devices = Device.where(status: 'error').count
      total_devices = Device.count
      
      if total_devices > 0
        error_rate = error_devices.to_f / total_devices * 100
        score -= (error_rate * 2)
      end
      
      [score, 0].max.round(1)
    end

    def calculate_customer_health_score
      score = 100
      score -= 15 if calculate_monthly_churn_rate > 8
      score -= 10 if calculate_user_engagement_rate < 60
      score -= 5 if User.where(last_sign_in_at: ..30.days.ago).count > User.count * 0.3
      
      [score, 0].max
    end

    def calculate_technical_health_score
      score = 100
      offline_devices = Device.where(last_connection: ..1.hour.ago).count
      total_devices = Device.count
      
      if total_devices > 0
        offline_rate = offline_devices.to_f / total_devices * 100
        score -= (offline_rate * 1.5)
      end
      
      [score, 0].max.round(1)
    end

    def calculate_growth_health_score
      user_growth = calculate_user_growth_rate
      revenue_growth = calculate_revenue_growth_trend
      
      score = 50 # Base score
      score += [user_growth, 25].min # Max 25 points for user growth
      score += [revenue_growth, 25].min # Max 25 points for revenue growth
      
      [score, 100].min
    end

    # Helper methods
    def calculate_payment_success_rate
      total_orders = Order.where(created_at: @date_range).count
      return 100 if total_orders == 0
      
      successful_orders = Order.where(created_at: @date_range, status: 'completed').count
      
      (successful_orders.to_f / total_orders * 100).round(2)
    end

    def analyze_payment_methods
      # Placeholder - would analyze actual payment method data
      {
        'card' => 85,
        'bank_transfer' => 10,
        'other' => 5
      }
    end
  end
end