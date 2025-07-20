# app/services/admin/billing_analytics_service.rb
module Admin
  class BillingAnalyticsService < ApplicationService
    def initialize(period = 'month')
      @period = period
      @date_range = calculate_date_range(period)
    end

    def call
      begin
        analytics = {
          revenue_metrics: calculate_revenue_metrics,
          subscription_metrics: calculate_subscription_metrics,
          plan_distribution: calculate_plan_distribution,
          churn_analysis: calculate_churn_analysis,
          growth_metrics: calculate_growth_metrics,
          financial_health: calculate_financial_health,
          period_comparison: calculate_period_comparison
        }

        success(
          period: @period,
          date_range: {
            start: @date_range.begin.iso8601,
            end: @date_range.end.iso8601
          },
          analytics: analytics,
          summary: generate_analytics_summary(analytics),
          last_updated: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Billing analytics error: #{e.message}"
        failure("Failed to generate billing analytics: #{e.message}")
      end
    end

    private

    attr_reader :period, :date_range

    def calculate_revenue_metrics
      {
        total_mrr: calculate_total_mrr,
        new_mrr: calculate_new_mrr,
        churned_mrr: calculate_churned_mrr,
        expansion_mrr: calculate_expansion_mrr,
        contraction_mrr: calculate_contraction_mrr,
        net_mrr_growth: calculate_net_mrr_growth,
        arr: calculate_arr,
        average_revenue_per_user: calculate_arpu,
        lifetime_value: calculate_ltv
      }
    end

    def calculate_subscription_metrics
      {
        new_subscriptions: Subscription.where(created_at: date_range).count,
        canceled_subscriptions: Subscription.where(updated_at: date_range, status: 'canceled').count,
        reactivated_subscriptions: calculate_reactivated_subscriptions,
        past_due_subscriptions: Subscription.past_due.count,
        active_subscriptions: Subscription.active.count,
        total_subscriptions: Subscription.count,
        trial_conversions: calculate_trial_conversions,
        subscription_retention_rate: calculate_retention_rate
      }
    end

    def calculate_plan_distribution
      active_subs = Subscription.active.joins(:plan)
      
      {
        by_plan: active_subs.group('plans.name').count,
        by_revenue: active_subs.group('plans.name').sum('plans.monthly_price'),
        by_device_limit: active_subs.joins(:plan).group('plans.device_limit').count,
        plan_performance: analyze_plan_performance,
        upgrade_trends: analyze_upgrade_trends,
        most_popular: active_subs.group('plans.name').count.max_by { |k, v| v }&.first
      }
    end

    def calculate_churn_analysis
      churned_subs = Subscription.where(status: 'canceled')
      
      {
        churn_rate: calculate_churn_rate,
        churn_by_tenure: analyze_churn_by_tenure(churned_subs),
        churn_reasons: analyze_churn_reasons(churned_subs),
        recoverable_churn: calculate_recoverable_churn,
        churn_impact: calculate_churn_impact(churned_subs),
        churn_trends: analyze_churn_trends
      }
    end

    def calculate_growth_metrics
      {
        subscriber_growth_rate: calculate_subscriber_growth_rate,
        revenue_growth_rate: calculate_revenue_growth_rate,
        net_revenue_retention: calculate_net_revenue_retention,
        gross_revenue_retention: calculate_gross_revenue_retention,
        quick_ratio: calculate_quick_ratio,
        months_to_recover_cac: calculate_cac_payback
      }
    end

    def calculate_financial_health
      {
        monthly_recurring_revenue: calculate_total_mrr,
        revenue_concentration: calculate_revenue_concentration,
        payment_failure_rate: calculate_payment_failure_rate,
        outstanding_invoices: calculate_outstanding_invoices,
        cash_flow_health: analyze_cash_flow_health,
        subscription_cohort_value: analyze_subscription_cohorts
      }
    end

    def calculate_period_comparison
      previous_period = calculate_previous_period_range
      
      {
        mrr_change: calculate_metric_change('mrr', previous_period),
        subscriber_change: calculate_metric_change('subscribers', previous_period),
        churn_change: calculate_metric_change('churn_rate', previous_period),
        arpu_change: calculate_metric_change('arpu', previous_period),
        key_improvements: identify_key_improvements(previous_period),
        areas_of_concern: identify_areas_of_concern(previous_period)
      }
    end

    # Revenue Calculations
    def calculate_total_mrr
      Subscription.active.joins(:plan).sum('plans.monthly_price')
    end

    def calculate_new_mrr
      new_subs = Subscription.where(created_at: date_range, status: 'active')
      new_subs.joins(:plan).sum('plans.monthly_price')
    end

    def calculate_churned_mrr
      churned_subs = Subscription.where(updated_at: date_range, status: 'canceled')
      churned_subs.joins(:plan).sum('plans.monthly_price')
    end

    def calculate_expansion_mrr
      # Track plan upgrades and additional device slots
      expansion = 0
      
      # Plan upgrades
      subscription_changes = SubscriptionChange.where(
        created_at: date_range,
        change_type: 'plan_upgrade'
      )
      expansion += subscription_changes.sum(:revenue_impact)
      
      # Additional device slots
      device_slot_purchases = ExtraDeviceSlot.where(created_at: date_range)
      expansion += device_slot_purchases.count * 10 # Assume $10 per slot
      
      expansion
    end

    def calculate_contraction_mrr
      # Track plan downgrades
      downgrades = SubscriptionChange.where(
        created_at: date_range,
        change_type: 'plan_downgrade'
      )
      downgrades.sum(:revenue_impact).abs
    end

    def calculate_net_mrr_growth
      new_mrr = calculate_new_mrr
      expansion_mrr = calculate_expansion_mrr
      churned_mrr = calculate_churned_mrr
      contraction_mrr = calculate_contraction_mrr
      
      (new_mrr + expansion_mrr) - (churned_mrr + contraction_mrr)
    end

    def calculate_arr
      calculate_total_mrr * 12
    end

    def calculate_arpu
      active_subscribers = Subscription.active.count
      return 0 if active_subscribers == 0
      
      calculate_total_mrr / active_subscribers
    end

    def calculate_ltv
      monthly_churn_rate = calculate_churn_rate / 100
      return 0 if monthly_churn_rate == 0
      
      arpu = calculate_arpu
      customer_lifetime_months = 1 / monthly_churn_rate
      
      arpu * customer_lifetime_months
    end

    # Subscription Metrics
    def calculate_reactivated_subscriptions
      Subscription.where(
        updated_at: date_range,
        status: 'active'
      ).where.not(created_at: date_range).count
    end

    def calculate_trial_conversions
      # Assuming trials convert when they get an active subscription after trial period
      trial_users = User.joins(:subscription).where(
        subscriptions: { created_at: date_range, status: 'active' }
      ).where('subscriptions.trial_end IS NOT NULL')
      
      trial_users.count
    end

    def calculate_retention_rate
      return 0 if date_range.begin < 1.month.ago
      
      start_of_period_subs = Subscription.where(
        created_at: ..date_range.begin,
        status: 'active'
      ).count
      
      return 0 if start_of_period_subs == 0
      
      still_active = Subscription.where(
        created_at: ..date_range.begin,
        status: 'active'
      ).where(
        'updated_at < ? OR status = ?',
        date_range.end,
        'active'
      ).count
      
      (still_active.to_f / start_of_period_subs * 100).round(2)
    end

    # Churn Analysis
    def calculate_churn_rate
      start_of_period = Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        date_range.begin,
        date_range.begin
      ).count
      
      return 0 if start_of_period == 0
      
      churned_in_period = Subscription.where(
        canceled_at: date_range,
        created_at: ..date_range.begin
      ).count
      
      (churned_in_period.to_f / start_of_period * 100).round(2)
    end

    def analyze_churn_by_tenure(churned_subs)
      {
        'under_30_days' => churned_subs.where('canceled_at - created_at < INTERVAL \'30 days\'').count,
        '30_to_90_days' => churned_subs.where('canceled_at - created_at BETWEEN INTERVAL \'30 days\' AND INTERVAL \'90 days\'').count,
        'over_90_days' => churned_subs.where('canceled_at - created_at > INTERVAL \'90 days\'').count
      }
    end

    def analyze_churn_reasons(churned_subs)
      # Analyze based on payment failures, support tickets, etc.
      payment_related = churned_subs.joins(:user).joins(
        'LEFT JOIN orders ON orders.user_id = users.id AND orders.status = \'payment_failed\''
      ).where.not('orders.id' => nil).distinct.count
      
      {
        'payment_failed' => payment_related,
        'voluntary' => churned_subs.count - payment_related,
        'other' => 0
      }
    end

    def calculate_recoverable_churn
      past_due_subs = Subscription.past_due.where(updated_at: 7.days.ago..)
      failed_payments = Order.where(
        status: 'payment_failed',
        created_at: 3.days.ago..
      ).distinct.count(:user_id)
      
      {
        past_due_recoverable: past_due_subs.count,
        failed_payment_retry: failed_payments,
        total_recoverable: past_due_subs.count + failed_payments
      }
    end

    def calculate_churn_impact(churned_subs)
      {
        lost_mrr: churned_subs.joins(:plan).sum('plans.monthly_price'),
        lost_arr: churned_subs.joins(:plan).sum('plans.monthly_price') * 12,
        average_churned_tenure: calculate_average_churned_tenure(churned_subs)
      }
    end

    # Growth Metrics
    def calculate_subscriber_growth_rate
      previous_period = calculate_previous_period_range
      
      current_subs = Subscription.active.count
      previous_subs = Subscription.where(
        created_at: ..previous_period.end,
        status: 'active'
      ).where(
        'canceled_at IS NULL OR canceled_at > ?',
        previous_period.end
      ).count
      
      return 0 if previous_subs == 0
      
      ((current_subs - previous_subs).to_f / previous_subs * 100).round(2)
    end

    def calculate_revenue_growth_rate
      previous_period = calculate_previous_period_range
      
      current_revenue = calculate_total_mrr
      previous_revenue = calculate_mrr_for_period(previous_period)
      
      return 0 if previous_revenue == 0
      
      ((current_revenue - previous_revenue) / previous_revenue * 100).round(2)
    end

    def calculate_net_revenue_retention
      # Track revenue from existing customers over time
      # This is a simplified calculation
      cohort_start = 1.year.ago
      cohort_subs = Subscription.where(created_at: cohort_start.beginning_of_month..cohort_start.end_of_month)
      
      return 0 if cohort_subs.empty?
      
      initial_revenue = cohort_subs.joins(:plan).sum('plans.monthly_price')
      current_revenue = cohort_subs.where(status: 'active').joins(:plan).sum('plans.monthly_price')
      
      return 0 if initial_revenue == 0
      
      (current_revenue / initial_revenue * 100).round(2)
    end

    # Helper Methods
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
      duration = date_range.end - date_range.begin
      start_time = date_range.begin - duration
      end_time = date_range.begin
      
      start_time..end_time
    end

    def generate_analytics_summary(analytics)
      {
        total_mrr: analytics[:revenue_metrics][:total_mrr],
        mrr_growth: analytics[:revenue_metrics][:net_mrr_growth],
        active_subscribers: analytics[:subscription_metrics][:active_subscriptions],
        churn_rate: analytics[:churn_analysis][:churn_rate],
        health_score: calculate_overall_health_score(analytics)
      }
    end

    def calculate_overall_health_score(analytics)
      score = 100
      
      # Deduct points for high churn
      churn_rate = analytics[:churn_analysis][:churn_rate]
      score -= (churn_rate * 2) if churn_rate > 5
      
      # Deduct points for negative growth
      growth_rate = analytics[:growth_metrics][:revenue_growth_rate]
      score -= 20 if growth_rate < 0
      
      # Deduct points for high payment failures
      payment_failure_rate = calculate_payment_failure_rate
      score -= (payment_failure_rate * 1.5) if payment_failure_rate > 10
      
      [score, 0].max.round(1)
    end

    # Stub methods that would need full implementation
    def analyze_plan_performance
      Plan.joins(:subscriptions).where(subscriptions: { status: 'active' }).group('plans.name').count
    end

    def analyze_upgrade_trends
      # Would track plan changes over time
      {}
    end

    def analyze_churn_trends
      # Would analyze churn patterns over multiple periods
      'stable'
    end

    def calculate_gross_revenue_retention
      85.0 # Placeholder - would calculate actual GRR
    end

    def calculate_quick_ratio
      # (New MRR + Expansion MRR) / (Churned MRR + Contraction MRR)
      growth = calculate_new_mrr + calculate_expansion_mrr
      contraction = calculate_churned_mrr + calculate_contraction_mrr
      
      return 0 if contraction == 0
      growth / contraction
    end

    def calculate_cac_payback
      # Placeholder - would need customer acquisition cost data
      6.0
    end

    def calculate_revenue_concentration
      # Analyze revenue concentration among top customers
      top_customers_revenue = User.joins(subscription: :plan)
        .where(subscriptions: { status: 'active' })
        .order('plans.monthly_price DESC')
        .limit(10)
        .sum('plans.monthly_price')
      
      total_mrr = calculate_total_mrr
      return 0 if total_mrr == 0
      
      (top_customers_revenue / total_mrr * 100).round(1)
    end

    def calculate_payment_failure_rate
      total_orders = Order.where(created_at: date_range).count
      return 0 if total_orders == 0
      
      failed_orders = Order.where(created_at: date_range, status: 'payment_failed').count
      (failed_orders.to_f / total_orders * 100).round(1)
    end

    def calculate_outstanding_invoices
      # Placeholder - would integrate with billing system
      {
        count: 0,
        total_amount: 0
      }
    end

    def analyze_cash_flow_health
      {
        status: 'healthy',
        monthly_inflow: calculate_total_mrr,
        monthly_outflow: 0, # Would track refunds, chargebacks
        net_cash_flow: calculate_total_mrr
      }
    end

    def analyze_subscription_cohorts
      # Analyze cohorts by signup month
      User.joins(:subscription)
        .where(subscriptions: { status: 'active' })
        .group_by_month(:created_at)
        .count
    end

    def calculate_metric_change(metric, previous_period)
      # Calculate percentage change from previous period
      current_value = send("calculate_current_#{metric}")
      previous_value = send("calculate_previous_#{metric}", previous_period)
      
      return 0 if previous_value == 0
      
      ((current_value - previous_value) / previous_value * 100).round(2)
    end

    def identify_key_improvements(previous_period)
      # Identify metrics that improved significantly
      []
    end

    def identify_areas_of_concern(previous_period)
      # Identify metrics that worsened significantly
      []
    end

    def calculate_mrr_for_period(period_range)
      # Calculate MRR at the end of the specified period
      subscriptions_at_end = Subscription.where(
        created_at: ..period_range.end
      ).where(
        'status = ? OR (status = ? AND canceled_at > ?)',
        'active',
        'canceled',
        period_range.end
      )
      
      subscriptions_at_end.joins(:plan).sum('plans.monthly_price')
    end

    def calculate_average_churned_tenure(churned_subs)
      return 0 if churned_subs.empty?
      
      total_tenure = churned_subs.sum do |sub|
        (sub.canceled_at - sub.created_at).to_i / 1.day
      end
      
      (total_tenure.to_f / churned_subs.count).round(1)
    end

    # Placeholder methods for metric changes
    def calculate_current_mrr
      calculate_total_mrr
    end

    def calculate_previous_mrr(previous_period)
      calculate_mrr_for_period(previous_period)
    end

    def calculate_current_subscribers
      Subscription.active.count
    end

    def calculate_previous_subscribers(previous_period)
      Subscription.where(
        created_at: ..previous_period.end,
        status: 'active'
      ).count
    end

    def calculate_current_churn_rate
      calculate_churn_rate
    end

    def calculate_previous_churn_rate(previous_period)
      # Would calculate churn rate for previous period
      0
    end

    def calculate_current_arpu
      calculate_arpu
    end

    def calculate_previous_arpu(previous_period)
      # Would calculate ARPU for previous period
      0
    end
  end
end