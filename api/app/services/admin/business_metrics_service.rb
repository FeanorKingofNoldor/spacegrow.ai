# app/services/admin/business_metrics_service.rb
module Admin
  class BusinessMetricsService < ApplicationService
    def initialize(period = 'month')
      @period = period
      @date_range = calculate_date_range(period)
    end

    def call
      begin
        business_metrics = {
          revenue_metrics: calculate_revenue_metrics,
          customer_metrics: calculate_customer_metrics,
          subscription_metrics: calculate_subscription_metrics,
          growth_metrics: calculate_growth_metrics
        }

        success(
          business_metrics: business_metrics,
          period: @period,
          date_range: {
            start: @date_range.begin.iso8601,
            end: @date_range.end.iso8601
          },
          summary: generate_business_summary(business_metrics),
          key_insights: generate_actionable_insights(business_metrics),
          last_updated: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Business metrics error: #{e.message}"
        failure("Failed to calculate business metrics: #{e.message}")
      end
    end

    private

    attr_reader :period, :date_range

    # ===== REVENUE METRICS (Real Data) =====
    
    def calculate_revenue_metrics
      {
        # Core Revenue
        total_revenue: calculate_total_revenue,
        monthly_recurring_revenue: calculate_monthly_recurring_revenue,
        annual_recurring_revenue: calculate_annual_recurring_revenue,
        one_time_revenue: calculate_one_time_revenue,
        
        # Revenue Growth
        revenue_growth_rate: calculate_revenue_growth_rate,
        mrr_growth_rate: calculate_mrr_growth_rate,
        
        # Revenue Distribution
        revenue_by_plan: analyze_revenue_by_plan,
        average_order_value: calculate_average_order_value,
        revenue_per_customer: calculate_revenue_per_customer
      }
    end

    def calculate_total_revenue
      Order.where(created_at: @date_range, status: 'completed').sum(:total)
    end

    def calculate_monthly_recurring_revenue
      Subscription.where(status: 'active').joins(:plan).sum('plans.monthly_price')
    end

    def calculate_annual_recurring_revenue
      calculate_monthly_recurring_revenue * 12
    end

    def calculate_one_time_revenue
      # Revenue from device sales and one-time purchases
      Order.where(created_at: @date_range, status: 'completed')
           .where.not(subscription_id: nil) # Exclude subscription charges
           .sum(:total)
    end

    def calculate_revenue_growth_rate
      current_revenue = calculate_total_revenue
      previous_period = calculate_previous_period_range
      previous_revenue = Order.where(created_at: previous_period, status: 'completed').sum(:total)
      
      return 0 if previous_revenue == 0
      ((current_revenue - previous_revenue).to_f / previous_revenue * 100).round(2)
    end

    def calculate_mrr_growth_rate
      current_mrr = calculate_monthly_recurring_revenue
      
      # Calculate MRR from previous month
      previous_month_active_subs = Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        1.month.ago.end_of_month,
        1.month.ago.end_of_month
      ).joins(:plan)
      
      previous_mrr = previous_month_active_subs.sum('plans.monthly_price')
      
      return 0 if previous_mrr == 0
      ((current_mrr - previous_mrr).to_f / previous_mrr * 100).round(2)
    end

    def analyze_revenue_by_plan
      Subscription.where(status: 'active')
                  .joins(:plan)
                  .group('plans.name')
                  .sum('plans.monthly_price')
    end

    def calculate_average_order_value
      completed_orders = Order.where(created_at: @date_range, status: 'completed')
      return 0 if completed_orders.empty?
      (completed_orders.sum(:total) / completed_orders.count).round(2)
    end

    def calculate_revenue_per_customer
      active_customers = User.joins(:subscription).where(subscriptions: { status: 'active' }).count
      return 0 if active_customers == 0
      (calculate_monthly_recurring_revenue / active_customers).round(2)
    end

    # ===== CUSTOMER METRICS (Real Data) =====
    
    def calculate_customer_metrics
      {
        # Customer Base
        total_customers: count_total_customers,
        active_customers: count_active_customers,
        new_customers: count_new_customers,
        
        # Customer Economics
        customer_acquisition_cost: calculate_customer_acquisition_cost,
        customer_lifetime_value: calculate_customer_lifetime_value,
        ltv_cac_ratio: calculate_ltv_cac_ratio,
        payback_period: calculate_payback_period,
        
        # Customer Health
        customer_churn_rate: calculate_customer_churn_rate,
        customer_retention_rate: calculate_customer_retention_rate,
        revenue_churn_rate: calculate_revenue_churn_rate
      }
    end

    def count_total_customers
      User.count
    end

    def count_active_customers
      User.joins(:subscription).where(subscriptions: { status: 'active' }).count
    end

    def count_new_customers
      User.where(created_at: @date_range).count
    end

    def calculate_customer_acquisition_cost
      # Simplified CAC based on marketing spend proxy (completed orders processing fees)
      total_new_customers = count_new_customers
      return 0 if total_new_customers == 0
      
      # Use order processing costs as a proxy for acquisition costs
      acquisition_costs = Order.where(created_at: @date_range, status: 'completed')
                              .sum(:total) * 0.03 # Assume 3% processing fees
                              
      (acquisition_costs / total_new_customers).round(2)
    end

    def calculate_customer_lifetime_value
      monthly_churn_rate = calculate_customer_churn_rate / 100
      return 0 if monthly_churn_rate == 0
      
      avg_revenue_per_customer = calculate_revenue_per_customer
      customer_lifetime_months = 1 / monthly_churn_rate
      
      (avg_revenue_per_customer * customer_lifetime_months).round(2)
    end

    def calculate_ltv_cac_ratio
      ltv = calculate_customer_lifetime_value
      cac = calculate_customer_acquisition_cost
      
      return 0 if cac == 0
      (ltv / cac).round(2)
    end

    def calculate_payback_period
      cac = calculate_customer_acquisition_cost
      monthly_revenue_per_customer = calculate_revenue_per_customer
      
      return 0 if monthly_revenue_per_customer == 0
      (cac / monthly_revenue_per_customer).round(1)
    end

    def calculate_customer_churn_rate
      # Customers who were active at start of period but canceled during period
      start_of_period_customers = User.joins(:subscription)
        .where('users.created_at <= ?', @date_range.begin)
        .where('subscriptions.status = ? OR (subscriptions.status = ? AND subscriptions.canceled_at > ?)',
               'active', 'canceled', @date_range.begin)
        .count
      
      return 0 if start_of_period_customers == 0
      
      churned_customers = User.joins(:subscription)
        .where('users.created_at <= ?', @date_range.begin)
        .where(subscriptions: { canceled_at: @date_range })
        .count
      
      (churned_customers.to_f / start_of_period_customers * 100).round(2)
    end

    def calculate_customer_retention_rate
      100 - calculate_customer_churn_rate
    end

    def calculate_revenue_churn_rate
      # Revenue lost from churned customers
      start_of_period_mrr = calculate_previous_period_mrr
      return 0 if start_of_period_mrr == 0
      
      churned_revenue = Subscription.where(canceled_at: @date_range)
                                  .joins(:plan)
                                  .sum('plans.monthly_price')
      
      (churned_revenue / start_of_period_mrr * 100).round(2)
    end

    # ===== SUBSCRIPTION METRICS (Real Data) =====
    
    def calculate_subscription_metrics
      {
        # Subscription Health
        active_subscriptions: count_active_subscriptions,
        new_subscriptions: count_new_subscriptions,
        canceled_subscriptions: count_canceled_subscriptions,
        subscription_growth_rate: calculate_subscription_growth_rate,
        
        # Plan Performance
        plan_distribution: analyze_plan_distribution,
        most_popular_plans: identify_most_popular_plans,
        
        # Subscription Economics
        average_revenue_per_user: calculate_average_revenue_per_user,
        subscription_value_distribution: analyze_subscription_value_distribution
      }
    end

    def count_active_subscriptions
      Subscription.where(status: 'active').count
    end

    def count_new_subscriptions
      Subscription.where(created_at: @date_range).count
    end

    def count_canceled_subscriptions
      Subscription.where(canceled_at: @date_range).count
    end

    def calculate_subscription_growth_rate
      current_subs = count_active_subscriptions
      previous_period = calculate_previous_period_range
      previous_subs = Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        previous_period.end,
        previous_period.end
      ).count
      
      return 0 if previous_subs == 0
      ((current_subs - previous_subs).to_f / previous_subs * 100).round(2)
    end

    def analyze_plan_distribution
      Subscription.where(status: 'active').joins(:plan).group('plans.name').count
    end

    def identify_most_popular_plans
      plan_counts = analyze_plan_distribution
      plan_counts.sort_by { |_, count| -count }.first(3).to_h
    end

    def calculate_average_revenue_per_user
      active_users = count_active_customers
      return 0 if active_users == 0
      (calculate_monthly_recurring_revenue / active_users).round(2)
    end

    def analyze_subscription_value_distribution
      subscriptions = Subscription.where(status: 'active').joins(:plan)
      
      {
        low_value: subscriptions.joins(:plan).where('plans.monthly_price < ?', 50).count,
        medium_value: subscriptions.joins(:plan).where('plans.monthly_price BETWEEN ? AND ?', 50, 150).count,
        high_value: subscriptions.joins(:plan).where('plans.monthly_price > ?', 150).count
      }
    end

    # ===== GROWTH METRICS (Real Data) =====
    
    def calculate_growth_metrics
      {
        # User Growth
        user_growth_rate: calculate_user_growth_rate,
        customer_growth_rate: calculate_customer_growth_rate,
        
        # Revenue Growth
        revenue_growth_rate: calculate_revenue_growth_rate,
        mrr_growth_rate: calculate_mrr_growth_rate,
        
        # Business Health
        net_revenue_retention: calculate_net_revenue_retention,
        growth_efficiency: calculate_growth_efficiency
      }
    end

    def calculate_user_growth_rate
      current_users = User.count
      previous_period = calculate_previous_period_range
      previous_users = User.where(created_at: ..previous_period.end).count
      
      return 0 if previous_users == 0
      ((current_users - previous_users).to_f / previous_users * 100).round(2)
    end

    def calculate_customer_growth_rate
      current_customers = count_active_customers
      previous_period = calculate_previous_period_range
      previous_customers = User.joins(:subscription)
        .where('users.created_at <= ?', previous_period.end)
        .where('subscriptions.created_at <= ?', previous_period.end)
        .where(subscriptions: { status: 'active' })
        .count
      
      return 0 if previous_customers == 0
      ((current_customers - previous_customers).to_f / previous_customers * 100).round(2)
    end

    def calculate_net_revenue_retention
      # Simplified NRR calculation
      previous_period_mrr = calculate_previous_period_mrr
      return 0 if previous_period_mrr == 0
      
      current_mrr = calculate_monthly_recurring_revenue
      churned_revenue = calculate_churned_revenue
      
      retained_and_expanded_revenue = current_mrr - calculate_new_customer_mrr
      (retained_and_expanded_revenue / previous_period_mrr * 100).round(2)
    end

    def calculate_growth_efficiency
      revenue_growth = calculate_revenue_growth_rate
      customer_growth = calculate_customer_growth_rate
      
      return 0 if customer_growth == 0
      (revenue_growth / customer_growth).round(2)
    end

    # ===== SUMMARY AND INSIGHTS =====
    
    def generate_business_summary(metrics)
      {
        revenue_health: assess_revenue_health(metrics[:revenue_metrics]),
        customer_health: assess_customer_health(metrics[:customer_metrics]),
        growth_health: assess_growth_health(metrics[:growth_metrics]),
        subscription_health: assess_subscription_health(metrics[:subscription_metrics])
      }
    end

    def generate_actionable_insights(metrics)
      insights = []
      
      # Revenue insights
      revenue_growth = metrics[:revenue_metrics][:revenue_growth_rate]
      if revenue_growth > 20
        insights << {
          type: 'positive',
          category: 'revenue',
          insight: 'Strong revenue growth indicates healthy business momentum',
          data_point: "#{revenue_growth}% growth"
        }
      elsif revenue_growth < 0
        insights << {
          type: 'warning',
          category: 'revenue',
          insight: 'Revenue decline needs immediate attention',
          data_point: "#{revenue_growth}% decline"
        }
      end
      
      # Customer insights
      ltv_cac = metrics[:customer_metrics][:ltv_cac_ratio]
      if ltv_cac > 3
        insights << {
          type: 'positive',
          category: 'customer_economics',
          insight: 'Healthy LTV:CAC ratio indicates sustainable unit economics',
          data_point: "#{ltv_cac}:1 ratio"
        }
      elsif ltv_cac < 1
        insights << {
          type: 'critical',
          category: 'customer_economics',
          insight: 'LTV:CAC ratio below 1 indicates unsustainable economics',
          data_point: "#{ltv_cac}:1 ratio"
        }
      end
      
      # Churn insights
      churn_rate = metrics[:customer_metrics][:customer_churn_rate]
      if churn_rate > 10
        insights << {
          type: 'warning',
          category: 'retention',
          insight: 'High churn rate requires immediate retention focus',
          data_point: "#{churn_rate}% monthly churn"
        }
      end
      
      insights
    end

    # ===== HEALTH ASSESSMENTS =====
    
    def assess_revenue_health(revenue_metrics)
      growth_rate = revenue_metrics[:revenue_growth_rate]
      mrr_growth = revenue_metrics[:mrr_growth_rate]
      
      if growth_rate > 15 && mrr_growth > 10
        'excellent'
      elsif growth_rate > 5 && mrr_growth > 0
        'good'
      elsif growth_rate > 0
        'fair'
      else
        'poor'
      end
    end

    def assess_customer_health(customer_metrics)
      ltv_cac = customer_metrics[:ltv_cac_ratio]
      churn_rate = customer_metrics[:customer_churn_rate]
      
      if ltv_cac > 3 && churn_rate < 5
        'excellent'
      elsif ltv_cac > 2 && churn_rate < 10
        'good'
      elsif ltv_cac > 1 && churn_rate < 15
        'fair'
      else
        'poor'
      end
    end

    def assess_growth_health(growth_metrics)
      user_growth = growth_metrics[:user_growth_rate]
      revenue_growth = growth_metrics[:revenue_growth_rate]
      
      if user_growth > 20 && revenue_growth > 15
        'excellent'
      elsif user_growth > 10 && revenue_growth > 5
        'good'
      elsif user_growth > 0 && revenue_growth > 0
        'fair'
      else
        'poor'
      end
    end

    def assess_subscription_health(subscription_metrics)
      growth_rate = subscription_metrics[:subscription_growth_rate]
      active_subs = subscription_metrics[:active_subscriptions]
      
      if growth_rate > 15 && active_subs > 100
        'excellent'
      elsif growth_rate > 5 && active_subs > 50
        'good'
      elsif growth_rate > 0
        'fair'
      else
        'poor'
      end
    end

    # ===== HELPER METHODS =====
    
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
      case @period
      when 'week'
        2.weeks.ago..1.week.ago
      when 'month'
        2.months.ago..1.month.ago
      when 'quarter'
        6.months.ago..3.months.ago
      when 'year'
        2.years.ago..1.year.ago
      else
        2.months.ago..1.month.ago
      end
    end

    def calculate_previous_period_mrr
      previous_period = calculate_previous_period_range
      Subscription.where(
        'created_at <= ? AND (canceled_at IS NULL OR canceled_at > ?)',
        previous_period.end,
        previous_period.end
      ).joins(:plan).sum('plans.monthly_price')
    end

    def calculate_churned_revenue
      Subscription.where(canceled_at: @date_range)
                  .joins(:plan)
                  .sum('plans.monthly_price')
    end

    def calculate_new_customer_mrr
      User.where(created_at: @date_range)
          .joins(subscription: :plan)
          .where(subscriptions: { status: 'active' })
          .sum('plans.monthly_price')
    end
  end
end