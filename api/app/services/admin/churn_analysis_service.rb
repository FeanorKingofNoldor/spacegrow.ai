# app/services/admin/churn_analysis_service.rb
module Admin
  class ChurnAnalysisService < ApplicationService
    def initialize(filter_params = {})
      @filter_params = filter_params
      @date_range = calculate_date_range
    end

    def call
      begin
        churned_subscriptions = build_churned_query
        
        analysis = {
          summary: build_churn_summary(churned_subscriptions),
          churn_patterns: analyze_churn_patterns(churned_subscriptions),
          cohort_analysis: perform_cohort_churn_analysis,
          risk_assessment: identify_churn_risk_users,
          financial_impact: calculate_churn_financial_impact(churned_subscriptions),
          prevention_insights: generate_prevention_insights(churned_subscriptions),
          recent_churned: serialize_recent_churned(churned_subscriptions.limit(10))
        }

        success(
          churn_analysis: analysis,
          period: filter_params[:period] || 'month',
          date_range: {
            start: @date_range.begin.iso8601,
            end: @date_range.end.iso8601
          },
          last_updated: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Churn analysis error: #{e.message}"
        failure("Failed to generate churn analysis: #{e.message}")
      end
    end

    private

    attr_reader :filter_params, :date_range

    def build_churned_query
      churned = Subscription.where(status: 'canceled').includes(:user, :plan)
      
      # Apply date filters
      churned = apply_date_filters(churned)
      churned = apply_plan_filter(churned)
      churned = apply_tenure_filter(churned)
      
      churned.order(canceled_at: :desc)
    end

    def apply_date_filters(churned)
      churned = churned.where(canceled_at: date_range.begin..) if filter_params[:created_after].present?
      churned = churned.where(canceled_at: ..date_range.end) if filter_params[:created_before].present?
      churned
    end

    def apply_plan_filter(churned)
      return churned unless filter_params[:plan_id].present?
      churned.where(plan_id: filter_params[:plan_id])
    end

    def apply_tenure_filter(churned)
      return churned unless filter_params[:tenure_range].present?
      
      case filter_params[:tenure_range]
      when 'under_30'
        churned.where('canceled_at - created_at < INTERVAL \'30 days\'')
      when '30_to_90'
        churned.where('canceled_at - created_at BETWEEN INTERVAL \'30 days\' AND INTERVAL \'90 days\'')
      when 'over_90'
        churned.where('canceled_at - created_at > INTERVAL \'90 days\'')
      else
        churned
      end
    end

    def build_churn_summary(churned_subscriptions)
      total_churned = churned_subscriptions.count
      
      {
        total_churned: total_churned,
        churn_rate: calculate_period_churn_rate,
        average_tenure: calculate_average_tenure(churned_subscriptions),
        lost_revenue: calculate_lost_revenue(churned_subscriptions),
        churn_by_plan: churned_subscriptions.joins(:plan).group('plans.name').count,
        churn_velocity: calculate_churn_velocity,
        top_churn_reasons: analyze_top_churn_reasons(churned_subscriptions)
      }
    end

    def analyze_churn_patterns(churned_subscriptions)
      {
        churn_by_tenure: analyze_churn_by_tenure(churned_subscriptions),
        churn_by_month: analyze_monthly_churn_patterns,
        churn_by_plan_type: analyze_churn_by_plan_type(churned_subscriptions),
        churn_seasonality: analyze_churn_seasonality,
        early_vs_late_churn: analyze_early_vs_late_churn(churned_subscriptions)
      }
    end

    def perform_cohort_churn_analysis
      cohorts = {}
      
      # Analyze churn by signup month
      (12.months.ago.to_date..Date.current).group_by(&:beginning_of_month).each do |month, _|
        cohort_users = User.joins(:subscription).where(created_at: month.all_month)
        next if cohort_users.empty?
        
        total_in_cohort = cohort_users.count
        churned_in_cohort = cohort_users.joins(:subscription).where(
          subscriptions: { status: 'canceled', canceled_at: month.. }
        ).count
        
        cohorts[month.strftime('%Y-%m')] = {
          total_users: total_in_cohort,
          churned_users: churned_in_cohort,
          churn_rate: total_in_cohort > 0 ? (churned_in_cohort.to_f / total_in_cohort * 100).round(2) : 0,
          retained_users: total_in_cohort - churned_in_cohort,
          retention_rate: total_in_cohort > 0 ? ((total_in_cohort - churned_in_cohort).to_f / total_in_cohort * 100).round(2) : 0
        }
      end
      
      cohorts
    end

    def identify_churn_risk_users
      # Users showing signs they might churn based on real behavioral data
      risk_indicators = {}
      
      # Payment issues - real risk factor
      payment_risk_users = User.joins(:orders)
        .where(orders: { status: 'payment_failed', created_at: 7.days.ago.. })
        .joins(:subscription)
        .where(subscriptions: { status: ['active', 'past_due'] })
        .distinct
      
      # Inactive users - real behavioral indicator
      inactive_risk_users = User.joins(:subscription)
        .where(subscriptions: { status: 'active' })
        .where(last_sign_in_at: ..30.days.ago)
      
      # Over device limit users - real system constraint
      active_users_with_subscriptions = User.joins(:subscription).where(subscriptions: { status: 'active' })
      over_limit_users = active_users_with_subscriptions.select { |user| user.devices.count > user.device_limit }
      
      risk_indicators = {
        payment_issues: {
          count: payment_risk_users.count,
          users: serialize_risk_users(payment_risk_users.limit(5)),
          risk_level: 'high'
        },
        inactive_users: {
          count: inactive_risk_users.count,
          users: serialize_risk_users(inactive_risk_users.limit(5)),
          risk_level: 'medium'
        },
        over_device_limit: {
          count: over_limit_users.count,
          users: serialize_risk_users(over_limit_users.first(5)),
          risk_level: 'medium'
        }
      }
      
      # Calculate overall risk score based on real data
      total_at_risk = payment_risk_users.count + inactive_risk_users.count + over_limit_users.count
      total_active = Subscription.active.count
      
      risk_indicators[:overall_risk_score] = total_active > 0 ? 
        (total_at_risk.to_f / total_active * 100).round(2) : 0
      risk_indicators[:total_at_risk] = total_at_risk
      
      risk_indicators
    end

    def calculate_churn_financial_impact(churned_subscriptions)
      lost_mrr = churned_subscriptions.joins(:plan).sum('plans.monthly_price')
      lost_arr = lost_mrr * 12
      
      # Calculate lifetime value of churned customers using real order data
      churned_user_ids = churned_subscriptions.pluck(:user_id)
      historical_value = Order.where(user_id: churned_user_ids, status: 'completed').sum(:total)
      
      {
        lost_monthly_revenue: lost_mrr,
        lost_annual_revenue: lost_arr,
        historical_customer_value: historical_value,
        average_lost_value_per_customer: churned_subscriptions.count > 0 ? (historical_value / churned_subscriptions.count).round(2) : 0,
        recoverable_revenue: calculate_recoverable_revenue
      }
    end

    def generate_prevention_insights(churned_subscriptions)
      insights = []
      
      # Early churn analysis - actionable insight
      early_churners = churned_subscriptions.where('canceled_at - created_at < INTERVAL \'30 days\'')
      if early_churners.count > churned_subscriptions.count * 0.3
        insights << {
          type: 'early_churn_warning',
          severity: 'high',
          insight: 'High early churn rate detected - focus on onboarding improvements',
          affected_count: early_churners.count,
          percentage: ((early_churners.count.to_f / churned_subscriptions.count) * 100).round(1),
          recommended_actions: ['Improve onboarding flow', 'Enhance initial user experience', 'Provide better getting started resources']
        }
      end
      
      # Payment-related churn analysis - actionable insight
      payment_churners = churned_subscriptions.joins(:user).joins(
        'LEFT JOIN orders ON orders.user_id = users.id AND orders.status = \'payment_failed\''
      ).where.not('orders.id' => nil).distinct
      
      if payment_churners.count > churned_subscriptions.count * 0.4
        insights << {
          type: 'payment_churn_warning',
          severity: 'high',
          insight: 'Payment issues are a major churn driver',
          affected_count: payment_churners.count,
          percentage: ((payment_churners.count.to_f / churned_subscriptions.count) * 100).round(1),
          recommended_actions: ['Improve payment retry logic', 'Proactive payment failure outreach', 'Payment method backup systems']
        }
      end
      
      # Plan-specific churn analysis - actionable insight
      plan_churn_rates = analyze_plan_specific_churn_rates(churned_subscriptions)
      problematic_plans = plan_churn_rates.select { |plan, rate| rate > 15 }
      
      if problematic_plans.any?
        insights << {
          type: 'plan_churn_warning',
          severity: 'medium',
          insight: 'Certain plans have higher churn rates',
          affected_plans: problematic_plans.keys,
          churn_rates: problematic_plans,
          recommended_actions: ['Review plan value proposition', 'Adjust pricing strategy', 'Enhance plan features']
        }
      end
      
      insights
    end

    # ===== REAL CALCULATION METHODS =====

    def calculate_period_churn_rate
      # Calculate churn rate for the current period using real data
      start_of_period_active = Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        date_range.begin,
        date_range.begin
      ).count
      
      return 0 if start_of_period_active == 0
      
      churned_in_period = Subscription.where(
        canceled_at: date_range,
        created_at: ..date_range.begin
      ).count
      
      (churned_in_period.to_f / start_of_period_active * 100).round(2)
    end

    def calculate_average_tenure(churned_subscriptions)
      return 0 if churned_subscriptions.empty?
      
      total_tenure_days = churned_subscriptions.sum do |sub|
        (sub.canceled_at - sub.created_at).to_i / 1.day
      end
      
      (total_tenure_days.to_f / churned_subscriptions.count).round(1)
    end

    def calculate_lost_revenue(churned_subscriptions)
      churned_subscriptions.joins(:plan).sum('plans.monthly_price')
    end

    def calculate_churn_velocity
      # Rate of churn acceleration/deceleration using real data
      current_period_churn = Subscription.where(canceled_at: date_range).count
      previous_period = (date_range.end - date_range.begin).seconds.ago..(date_range.begin)
      previous_period_churn = Subscription.where(canceled_at: previous_period).count
      
      return 0 if previous_period_churn == 0
      
      ((current_period_churn - previous_period_churn).to_f / previous_period_churn * 100).round(2)
    end

    def analyze_top_churn_reasons(churned_subscriptions)
      reasons = {}
      
      # Payment failures - real data analysis
      payment_churned = churned_subscriptions.joins(:user).joins(
        'LEFT JOIN orders ON orders.user_id = users.id AND orders.status = \'payment_failed\''
      ).where.not('orders.id' => nil).distinct.count
      
      # Device limit exceeded - real system constraint
      over_limit_churned = churned_subscriptions.joins(:user).select do |sub|
        sub.user.devices.count > sub.device_limit
      end.count
      
      # Inactivity-based churn
      inactive_churned = churned_subscriptions.joins(:user).where(
        'users.last_sign_in_at < ?', 30.days.ago
      ).count
      
      reasons['payment_issues'] = payment_churned
      reasons['device_limit_exceeded'] = over_limit_churned
      reasons['inactivity'] = inactive_churned
      reasons['voluntary'] = churned_subscriptions.count - payment_churned - over_limit_churned - inactive_churned
      
      reasons
    end

    def analyze_churn_by_tenure(churned_subscriptions)
      {
        'under_30_days' => churned_subscriptions.where('canceled_at - created_at < INTERVAL \'30 days\'').count,
        '30_to_90_days' => churned_subscriptions.where('canceled_at - created_at BETWEEN INTERVAL \'30 days\' AND INTERVAL \'90 days\'').count,
        'over_90_days' => churned_subscriptions.where('canceled_at - created_at > INTERVAL \'90 days\'').count
      }
    end

    def analyze_monthly_churn_patterns
      # Real monthly pattern analysis
      monthly_churn = Subscription.where(status: 'canceled', canceled_at: 12.months.ago..)
        .group_by_month(:canceled_at)
        .count
      
      monthly_churn.transform_keys { |date| date.strftime('%Y-%m') }
    end

    def analyze_churn_by_plan_type(churned_subscriptions)
      churned_subscriptions.joins(:plan).group('plans.name').count
    end

    def analyze_churn_seasonality
      # Analyze seasonal patterns using real data
      seasonal_data = Subscription.where(status: 'canceled', canceled_at: 2.years.ago..)
        .group_by_month(:canceled_at)
        .count
      
      # Group by month (ignoring year) to see seasonal patterns
      by_month = Hash.new(0)
      seasonal_data.each do |date, count|
        month_key = date.strftime('%B')
        by_month[month_key] += count
      end
      
      by_month
    end

    def analyze_early_vs_late_churn(churned_subscriptions)
      early_churners = churned_subscriptions.where('canceled_at - created_at < INTERVAL \'30 days\'')
      late_churners = churned_subscriptions.where('canceled_at - created_at > INTERVAL \'90 days\'')
      
      {
        early_churn: {
          count: early_churners.count,
          average_tenure_days: calculate_average_tenure(early_churners),
          common_reasons: analyze_top_churn_reasons(early_churners)
        },
        late_churn: {
          count: late_churners.count,
          average_tenure_days: calculate_average_tenure(late_churners),
          value_delivered: calculate_value_delivered_before_churn(late_churners)
        }
      }
    end

    def calculate_value_delivered_before_churn(churned_subscriptions)
      return 0 if churned_subscriptions.empty?
      
      # Calculate total value from orders for churned customers
      churned_user_ids = churned_subscriptions.pluck(:user_id)
      total_value = Order.where(user_id: churned_user_ids, status: 'completed').sum(:total)
      
      (total_value.to_f / churned_subscriptions.count).round(2)
    end

    def analyze_plan_specific_churn_rates(churned_subscriptions)
      plan_churn = {}
      
      Plan.all.each do |plan|
        total_subs = Subscription.where(plan: plan).count
        churned_subs = churned_subscriptions.where(plan: plan).count
        
        plan_churn[plan.name] = total_subs > 0 ? 
          (churned_subs.to_f / total_subs * 100).round(2) : 0
      end
      
      plan_churn
    end

    def calculate_recoverable_revenue
      # Revenue that could potentially be recovered from past due subscriptions
      Subscription.past_due.joins(:plan).sum('plans.monthly_price')
    end

    def serialize_recent_churned(subscriptions)
      subscriptions.map do |subscription|
        {
          id: subscription.id,
          user_email: subscription.user.email,
          plan_name: subscription.plan&.name,
          canceled_at: subscription.canceled_at.iso8601,
          tenure_days: (subscription.canceled_at - subscription.created_at).to_i / 1.day,
          monthly_value: subscription.plan&.monthly_price || 0,
          likely_reason: determine_likely_churn_reason(subscription)
        }
      end
    end

    def serialize_risk_users(users)
      users.map do |user|
        {
          id: user.id,
          email: user.email,
          plan_name: user.subscription&.plan&.name,
          last_sign_in: user.last_sign_in_at&.iso8601,
          devices_count: user.devices.count,
          device_limit: user.device_limit
        }
      end
    end

    def determine_likely_churn_reason(subscription)
      user = subscription.user
      
      # Check for payment failures
      if user.orders.where(status: 'payment_failed', created_at: 30.days.ago..).any?
        return 'payment_issues'
      end
      
      # Check for inactivity
      if user.last_sign_in_at && user.last_sign_in_at < 30.days.ago
        return 'inactivity'
      end
      
      # Check for device limit issues
      if user.devices.count > user.device_limit
        return 'device_limit_exceeded'
      end
      
      'voluntary'
    end

    def calculate_date_range
      case filter_params[:period]
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
  end
end