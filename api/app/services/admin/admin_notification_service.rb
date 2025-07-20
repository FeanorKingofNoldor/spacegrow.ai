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
        churn_impact: calculate_churn_impact(churned_subs)
      }
    end

    def calculate_growth_metrics
      {
        subscriber_growth_rate: calculate_subscriber_growth_rate,
        revenue_growth_rate: calculate_revenue_growth_rate,
        net_revenue_retention: calculate_net_revenue_retention,
        quick_ratio: calculate_quick_ratio
      }
    end

    def calculate_financial_health
      {
        monthly_recurring_revenue: calculate_total_mrr,
        revenue_concentration: calculate_revenue_concentration,
        payment_failure_rate: calculate_payment_failure_rate,
        cash_flow_health: analyze_cash_flow_health,
        financial_health_score: calculate_financial_health_score
      }
    end

    def calculate_period_comparison
      previous_period = calculate_previous_period_range
      
      {
        mrr_change: calculate_mrr_change(previous_period),
        subscriber_change: calculate_subscriber_change(previous_period),
        churn_change: calculate_churn_change(previous_period),
        arpu_change: calculate_arpu_change(previous_period)
      }
    end

    # ===== REAL REVENUE CALCULATIONS =====

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
      expansion = 0
      
      # Plan upgrades (if SubscriptionChange model exists)
      if defined?(SubscriptionChange)
        subscription_changes = SubscriptionChange.where(
          created_at: date_range,
          change_type: 'plan_upgrade'
        )
        expansion += subscription_changes.sum(:revenue_impact)
      end
      
      # Additional device slots
      if defined?(ExtraDeviceSlot)
        device_slot_purchases = ExtraDeviceSlot.where(created_at: date_range)
        expansion += device_slot_purchases.joins(:subscription).joins(subscription: :plan)
                      .where(plans: { device_slot_price: 1.. })
                      .sum('plans.device_slot_price')
      end
      
      expansion
    end

    def calculate_contraction_mrr
      if defined?(SubscriptionChange)
        downgrades = SubscriptionChange.where(
          created_at: date_range,
          change_type: 'plan_downgrade'
        )
        downgrades.sum(:revenue_impact).abs
      else
        0
      end
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

    # ===== REAL SUBSCRIPTION METRICS =====

    def calculate_reactivated_subscriptions
      Subscription.where(
        updated_at: date_range,
        status: 'active'
      ).where.not(created_at: date_range).count
    end

    def calculate_trial_conversions
      # Users who converted from trial to paid subscription in this period
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

    # ===== REAL CHURN ANALYSIS =====

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
      # Analyze churn reasons based on available data
      reasons = {}
      
      # Payment failures
      payment_churned = churned_subs.joins(:user).joins(
        'LEFT JOIN orders ON orders.user_id = users.id AND orders.status = \'payment_failed\''
      ).where.not('orders.id' => nil).distinct.count
      
      reasons['payment_issues'] = payment_churned
      reasons['voluntary'] = churned_subs.count - payment_churned
      
      reasons
    end

    def calculate_recoverable_churn
      # Subscriptions that could potentially be recovered
      Subscription.past_due.count
    end

    def calculate_churn_impact(churned_subs)
      {
        lost_mrr: churned_subs.joins(:plan).sum('plans.monthly_price'),
        average_tenure: calculate_average_churned_tenure(churned_subs),
        total_customers_lost: churned_subs.count
      }
    end

    def calculate_average_churned_tenure(churned_subs)
      return 0 if churned_subs.empty?
      
      total_tenure = churned_subs.sum do |sub|
        (sub.canceled_at - sub.created_at).to_i / 1.day
      end
      
      (total_tenure.to_f / churned_subs.count).round(1)
    end

    # ===== REAL GROWTH METRICS =====

    def calculate_subscriber_growth_rate
      previous_period = calculate_previous_period_range
      current_subscribers = Subscription.active.count
      previous_subscribers = calculate_subscribers_for_period(previous_period)
      
      return 0 if previous_subscribers == 0
      
      ((current_subscribers - previous_subscribers).to_f / previous_subscribers * 100).round(2)
    end

    def calculate_revenue_growth_rate
      previous_period = calculate_previous_period_range
      current_mrr = calculate_total_mrr
      previous_mrr = calculate_mrr_for_period(previous_period)
      
      return 0 if previous_mrr == 0
      
      ((current_mrr - previous_mrr).to_f / previous_mrr * 100).round(2)
    end

    def calculate_net_revenue_retention
      # Calculate NRR based on cohort that existed at start of period
      previous_period = calculate_previous_period_range
      
      # Customers that existed at start of current period
      existing_customers = User.joins(:subscription).where(
        subscriptions: { created_at: ..date_range.begin }
      )
      
      # Their current MRR
      current_mrr_existing = existing_customers.joins(subscription: :plan)
        .where(subscriptions: { status: 'active' })
        .sum('plans.monthly_price')
      
      # Their MRR at start of period
      start_mrr_existing = calculate_mrr_for_existing_customers(existing_customers, date_range.begin)
      
      return 0 if start_mrr_existing == 0
      
      (current_mrr_existing.to_f / start_mrr_existing * 100).round(2)
    end

    def calculate_quick_ratio
      # (New MRR + Expansion MRR) / (Churned MRR + Contraction MRR)
      growth = calculate_new_mrr + calculate_expansion_mrr
      contraction = calculate_churned_mrr + calculate_contraction_mrr
      
      return 0 if contraction == 0
      (growth / contraction).round(2)
    end

    # ===== REAL FINANCIAL HEALTH =====

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

    def analyze_cash_flow_health
      total_mrr = calculate_total_mrr
      refunds_amount = Order.where(created_at: date_range, status: 'refunded').sum(:refund_amount)
      
      {
        monthly_inflow: total_mrr,
        monthly_outflow: refunds_amount,
        net_cash_flow: total_mrr - refunds_amount,
        status: total_mrr > refunds_amount ? 'healthy' : 'concerning'
      }
    end

    def calculate_financial_health_score
      score = 100
      
      # Deduct points for high churn
      churn_rate = calculate_churn_rate
      score -= (churn_rate * 2) if churn_rate > 5
      
      # Deduct points for high payment failures
      payment_failure_rate = calculate_payment_failure_rate
      score -= (payment_failure_rate * 1.5) if payment_failure_rate > 10
      
      # Deduct points for negative growth
      growth_rate = calculate_revenue_growth_rate
      score -= 20 if growth_rate < 0
      
      [score, 0].max.round(1)
    end

    # ===== REAL PERIOD COMPARISON =====

    def calculate_mrr_change(previous_period)
      current_mrr = calculate_total_mrr
      previous_mrr = calculate_mrr_for_period(previous_period)
      
      return 0 if previous_mrr == 0
      ((current_mrr - previous_mrr).to_f / previous_mrr * 100).round(2)
    end

    def calculate_subscriber_change(previous_period)
      current_subscribers = Subscription.active.count
      previous_subscribers = calculate_subscribers_for_period(previous_period)
      
      return 0 if previous_subscribers == 0
      ((current_subscribers - previous_subscribers).to_f / previous_subscribers * 100).round(2)
    end

    def calculate_churn_change(previous_period)
      current_churn = calculate_churn_rate
      previous_churn = calculate_churn_rate_for_period(previous_period)
      
      return 0 if previous_churn == 0
      ((current_churn - previous_churn).to_f / previous_churn * 100).round(2)
    end

    def calculate_arpu_change(previous_period)
      current_arpu = calculate_arpu
      previous_arpu = calculate_arpu_for_period(previous_period)
      
      return 0 if previous_arpu == 0
      ((current_arpu - previous_arpu).to_f / previous_arpu * 100).round(2)
    end

    # ===== REAL HELPER METHODS =====

    def analyze_plan_performance
      Plan.joins(:subscriptions)
          .where(subscriptions: { status: 'active' })
          .group('plans.name')
          .count
    end

    def calculate_mrr_for_period(period_range)
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

    def calculate_subscribers_for_period(period_range)
      Subscription.where(
        created_at: ..period_range.end,
        status: 'active'
      ).count
    end

    def calculate_churn_rate_for_period(period_range)
      start_of_period = Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        period_range.begin,
        period_range.begin
      ).count
      
      return 0 if start_of_period == 0
      
      churned_in_period = Subscription.where(
        canceled_at: period_range,
        created_at: ..period_range.begin
      ).count
      
      (churned_in_period.to_f / start_of_period * 100).round(2)
    end

    def calculate_arpu_for_period(period_range)
      mrr = calculate_mrr_for_period(period_range)
      subscribers = calculate_subscribers_for_period(period_range)
      
      return 0 if subscribers == 0
      mrr / subscribers
    end

    def calculate_mrr_for_existing_customers(customers, date)
      customers.joins(subscription: :plan)
               .where(subscriptions: { status: 'active', created_at: ..date })
               .sum('plans.monthly_price')
    end

    def generate_analytics_summary(analytics)
      {
        total_mrr: analytics[:revenue_metrics][:total_mrr],
        mrr_growth: analytics[:revenue_metrics][:net_mrr_growth],
        active_subscriptions: analytics[:subscription_metrics][:active_subscriptions],
        churn_rate: analytics[:churn_analysis][:churn_rate],
        health_score: analytics[:financial_health][:financial_health_score]
      }
    end

    def calculate_date_range(period)
      case period
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
      (date_range.begin - duration)..(date_range.begin)
    end
  end
end