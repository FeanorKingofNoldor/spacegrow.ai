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
          revenue_metrics: calculate_comprehensive_revenue_metrics,
          customer_metrics: calculate_customer_lifecycle_metrics,
          subscription_metrics: calculate_subscription_business_metrics,
          profitability_metrics: calculate_profitability_metrics,
          market_metrics: calculate_market_performance_metrics,
          growth_metrics: calculate_business_growth_metrics,
          efficiency_metrics: calculate_business_efficiency_metrics,
          forecasting: generate_business_forecasts
        }

        success(
          business_metrics: business_metrics,
          period: @period,
          date_range: {
            start: @date_range.begin.iso8601,
            end: @date_range.end.iso8601
          },
          executive_summary: generate_executive_summary(business_metrics),
          key_insights: generate_key_business_insights(business_metrics),
          action_items: generate_action_items(business_metrics),
          last_updated: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Business metrics error: #{e.message}"
        failure("Failed to calculate business metrics: #{e.message}")
      end
    end

    private

    attr_reader :period, :date_range

    def calculate_comprehensive_revenue_metrics
      {
        # Core Revenue
        total_revenue: calculate_total_revenue,
        recurring_revenue: calculate_monthly_recurring_revenue,
        annual_recurring_revenue: calculate_annual_recurring_revenue,
        one_time_revenue: calculate_one_time_revenue,
        
        # Revenue Growth
        revenue_growth_rate: calculate_revenue_growth_rate,
        mrr_growth_rate: calculate_mrr_growth_rate,
        net_revenue_retention: calculate_net_revenue_retention,
        gross_revenue_retention: calculate_gross_revenue_retention,
        
        # Revenue Quality
        revenue_concentration: calculate_revenue_concentration,
        revenue_predictability: calculate_revenue_predictability,
        revenue_per_customer: calculate_revenue_per_customer,
        average_contract_value: calculate_average_contract_value,
        
        # Revenue Sources
        revenue_by_plan: analyze_revenue_by_plan,
        revenue_by_customer_segment: analyze_revenue_by_segment,
        expansion_revenue: calculate_expansion_revenue,
        new_customer_revenue: calculate_new_customer_revenue
      }
    end

    def calculate_customer_lifecycle_metrics
      {
        # Acquisition
        customer_acquisition_cost: calculate_customer_acquisition_cost,
        acquisition_efficiency: calculate_acquisition_efficiency,
        new_customers: count_new_customers,
        signup_conversion_rate: calculate_signup_conversion_rate,
        
        # Retention & Churn
        customer_churn_rate: calculate_customer_churn_rate,
        revenue_churn_rate: calculate_revenue_churn_rate,
        customer_retention_rate: calculate_customer_retention_rate,
        cohort_retention_analysis: perform_cohort_retention_analysis,
        
        # Value
        customer_lifetime_value: calculate_customer_lifetime_value,
        ltv_cac_ratio: calculate_ltv_cac_ratio,
        payback_period: calculate_payback_period,
        customer_health_score: calculate_customer_health_score,
        
        # Expansion
        expansion_rate: calculate_expansion_rate,
        upsell_rate: calculate_upsell_rate,
        cross_sell_opportunities: identify_cross_sell_opportunities,
        customer_success_metrics: calculate_customer_success_metrics
      }
    end

    def calculate_subscription_business_metrics
      {
        # Subscription Health
        active_subscriptions: count_active_subscriptions,
        new_subscriptions: count_new_subscriptions,
        canceled_subscriptions: count_canceled_subscriptions,
        subscription_growth_rate: calculate_subscription_growth_rate,
        
        # Plan Performance
        plan_distribution: analyze_plan_distribution,
        plan_conversion_rates: calculate_plan_conversion_rates,
        plan_churn_rates: calculate_plan_churn_rates,
        most_popular_plans: identify_most_popular_plans,
        
        # Trial & Freemium
        trial_conversion_rate: calculate_trial_conversion_rate,
        trial_duration_analysis: analyze_trial_durations,
        freemium_conversion_metrics: calculate_freemium_metrics,
        activation_rate: calculate_activation_rate,
        
        # Subscription Economics
        average_revenue_per_user: calculate_arpu,
        average_revenue_per_account: calculate_arpa,
        subscription_length_analysis: analyze_subscription_lengths,
        pricing_efficiency: analyze_pricing_efficiency
      }
    end

    def calculate_profitability_metrics
      {
        # Margins
        gross_margin: calculate_gross_margin,
        contribution_margin: calculate_contribution_margin,
        operating_margin: calculate_operating_margin,
        net_margin: calculate_net_margin,
        
        # Unit Economics
        unit_economics_health: assess_unit_economics_health,
        contribution_margin_per_customer: calculate_contribution_margin_per_customer,
        break_even_analysis: perform_break_even_analysis,
        cost_structure_analysis: analyze_cost_structure,
        
        # Profitability Trends
        margin_trends: analyze_margin_trends,
        profitability_by_segment: analyze_profitability_by_segment,
        profitability_by_plan: analyze_profitability_by_plan,
        cost_efficiency_metrics: calculate_cost_efficiency_metrics
      }
    end

    def calculate_market_performance_metrics
      {
        # Market Position
        market_share_indicators: analyze_market_share_indicators,
        competitive_position: assess_competitive_position,
        brand_performance: measure_brand_performance,
        customer_satisfaction: measure_customer_satisfaction,
        
        # Product-Market Fit
        product_market_fit_score: calculate_pmf_score,
        feature_adoption_rates: analyze_feature_adoption,
        customer_feedback_analysis: analyze_customer_feedback,
        market_demand_indicators: assess_market_demand,
        
        # Market Expansion
        market_penetration_rate: calculate_market_penetration,
        expansion_opportunities: identify_market_expansion_opportunities,
        geographic_performance: analyze_geographic_performance,
        vertical_market_analysis: analyze_vertical_markets
      }
    end

    def calculate_business_growth_metrics
      {
        # Growth Rates
        overall_growth_rate: calculate_overall_growth_rate,
        customer_growth_rate: calculate_customer_growth_rate,
        revenue_growth_rate: calculate_revenue_growth_rate,
        organic_vs_paid_growth: analyze_growth_channels,
        
        # Growth Quality
        sustainable_growth_rate: calculate_sustainable_growth_rate,
        growth_efficiency: calculate_growth_efficiency,
        growth_investment_roi: calculate_growth_investment_roi,
        viral_coefficient: calculate_viral_coefficient,
        
        # Growth Drivers
        primary_growth_drivers: identify_primary_growth_drivers,
        growth_bottlenecks: identify_growth_bottlenecks,
        growth_opportunities: identify_growth_opportunities,
        growth_strategy_effectiveness: assess_growth_strategy_effectiveness
      }
    end

    def calculate_business_efficiency_metrics
      {
        # Operational Efficiency
        customer_service_efficiency: calculate_customer_service_efficiency,
        sales_efficiency: calculate_sales_efficiency,
        marketing_efficiency: calculate_marketing_efficiency,
        product_development_efficiency: calculate_product_development_efficiency,
        
        # Resource Utilization
        employee_productivity: calculate_employee_productivity,
        technology_utilization: assess_technology_utilization,
        capital_efficiency: calculate_capital_efficiency,
        time_to_value: calculate_time_to_value,
        
        # Process Efficiency
        automation_rate: calculate_automation_rate,
        error_rates: calculate_business_error_rates,
        cycle_times: measure_cycle_times,
        quality_metrics: calculate_quality_metrics
      }
    end

    def generate_business_forecasts
      {
        revenue_forecast: generate_revenue_forecast,
        customer_forecast: generate_customer_forecast,
        growth_projections: generate_growth_projections,
        profitability_projections: generate_profitability_projections,
        market_opportunity_forecast: generate_market_opportunity_forecast,
        risk_assessment: perform_risk_assessment,
        scenario_planning: perform_scenario_planning,
        strategic_recommendations: generate_strategic_recommendations
      }
    end

    # Core Revenue Calculations
    def calculate_total_revenue
      Order.where(created_at: @date_range, status: 'completed').sum(:total)
    end

    def calculate_monthly_recurring_revenue
      Subscription.active.joins(:plan).sum('plans.monthly_price')
    end

    def calculate_annual_recurring_revenue
      calculate_monthly_recurring_revenue * 12
    end

    def calculate_one_time_revenue
      # Revenue from one-time purchases (device sales, etc.)
      one_time_orders = Order.where(created_at: @date_range, status: 'completed')
        .joins(:line_items)
        .where.not(line_items: { product_type: 'Subscription' })
      
      one_time_orders.sum(:total)
    end

    def calculate_revenue_growth_rate
      current_revenue = calculate_total_revenue
      previous_period = calculate_previous_period_range
      previous_revenue = Order.where(created_at: previous_period, status: 'completed').sum(:total)
      
      return 0 if previous_revenue == 0
      
      ((current_revenue - previous_revenue) / previous_revenue * 100).round(2)
    end

    def calculate_mrr_growth_rate
      current_mrr = calculate_monthly_recurring_revenue
      previous_period = calculate_previous_period_range
      
      # Calculate MRR at end of previous period
      previous_mrr = calculate_mrr_at_date(previous_period.end)
      
      return 0 if previous_mrr == 0
      
      ((current_mrr - previous_mrr) / previous_mrr * 100).round(2)
    end

    # Customer Metrics
    def calculate_customer_acquisition_cost
      # Simplified CAC - would need marketing and sales spend data
      marketing_spend = 10000 # Placeholder
      sales_spend = 15000     # Placeholder
      
      new_customers = count_new_customers
      return 0 if new_customers == 0
      
      ((marketing_spend + sales_spend).to_f / new_customers).round(2)
    end

    def count_new_customers
      User.joins(:subscription).where(created_at: @date_range).count
    end

    def calculate_customer_churn_rate
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

    def calculate_customer_lifetime_value
      monthly_churn_rate = calculate_customer_churn_rate / 100
      return 0 if monthly_churn_rate == 0
      
      avg_revenue_per_customer = calculate_revenue_per_customer
      customer_lifetime_months = 1 / monthly_churn_rate
      
      (avg_revenue_per_customer * customer_lifetime_months).round(2)
    end

    # Business Health Indicators
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

    # Generate summaries and insights
    def generate_executive_summary(metrics)
      {
        revenue_health: assess_revenue_health(metrics[:revenue_metrics]),
        customer_health: assess_customer_health(metrics[:customer_metrics]),
        growth_health: assess_growth_health(metrics[:growth_metrics]),
        profitability_health: assess_profitability_health(metrics[:profitability_metrics]),
        overall_business_health: calculate_overall_business_health_score(metrics),
        key_achievements: identify_key_achievements(metrics),
        priority_areas: identify_priority_areas(metrics)
      }
    end

    def generate_key_business_insights(metrics)
      insights = []
      
      # Revenue insights
      if metrics[:revenue_metrics][:revenue_growth_rate] > 20
        insights << {
          type: 'positive',
          category: 'revenue',
          insight: 'Strong revenue growth indicates healthy business momentum',
          impact: 'high',
          data_point: "#{metrics[:revenue_metrics][:revenue_growth_rate]}% growth"
        }
      end
      
      # Customer insights
      ltv_cac = metrics[:customer_metrics][:ltv_cac_ratio]
      if ltv_cac > 3
        insights << {
          type: 'positive',
          category: 'customer_economics',
          insight: 'Healthy LTV:CAC ratio indicates sustainable unit economics',
          impact: 'high',
          data_point: "LTV:CAC ratio of #{ltv_cac}:1"
        }
      elsif ltv_cac < 1.5
        insights << {
          type: 'warning',
          category: 'customer_economics',
          insight: 'Low LTV:CAC ratio suggests acquisition costs are too high',
          impact: 'high',
          data_point: "LTV:CAC ratio of #{ltv_cac}:1"
        }
      end
      
      # Churn insights
      churn_rate = metrics[:customer_metrics][:customer_churn_rate]
      if churn_rate > 10
        insights << {
          type: 'warning',
          category: 'retention',
          insight: 'High churn rate is impacting growth and profitability',
          impact: 'high',
          data_point: "#{churn_rate}% monthly churn"
        }
      end
      
      insights
    end

    def generate_action_items(metrics)
      action_items = []
      
      # Based on business metrics, generate actionable recommendations
      ltv_cac = metrics[:customer_metrics][:ltv_cac_ratio]
      if ltv_cac < 2
        action_items << {
          priority: 'high',
          category: 'customer_acquisition',
          action: 'Optimize customer acquisition channels to reduce CAC',
          expected_impact: 'improve_unit_economics',
          timeline: '30_days'
        }
      end
      
      churn_rate = metrics[:customer_metrics][:customer_churn_rate]
      if churn_rate > 8
        action_items << {
          priority: 'high',
          category: 'retention',
          action: 'Implement churn reduction initiatives and customer success programs',
          expected_impact: 'reduce_churn_by_20%',
          timeline: '60_days'
        }
      end
      
      growth_rate = metrics[:growth_metrics][:overall_growth_rate]
      if growth_rate < 10
        action_items << {
          priority: 'medium',
          category: 'growth',
          action: 'Investigate growth bottlenecks and optimize growth channels',
          expected_impact: 'increase_growth_rate',
          timeline: '90_days'
        }
      end
      
      action_items
    end

    # Helper methods and calculations
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

    def calculate_revenue_per_customer
      active_customers = User.joins(:subscription).where(subscriptions: { status: 'active' }).count
      return 0 if active_customers == 0
      
      total_mrr = calculate_monthly_recurring_revenue
      (total_mrr.to_f / active_customers).round(2)
    end

    def calculate_overall_business_health_score(metrics)
      scores = []
      
      # Revenue health (25%)
      revenue_score = assess_revenue_health_score(metrics[:revenue_metrics])
      scores << { score: revenue_score, weight: 0.25 }
      
      # Customer health (25%)
      customer_score = assess_customer_health_score(metrics[:customer_metrics])
      scores << { score: customer_score, weight: 0.25 }
      
      # Growth health (25%)
      growth_score = assess_growth_health_score(metrics[:growth_metrics])
      scores << { score: growth_score, weight: 0.25 }
      
      # Profitability health (25%)
      profitability_score = assess_profitability_health_score(metrics[:profitability_metrics])
      scores << { score: profitability_score, weight: 0.25 }
      
      weighted_score = scores.sum { |s| s[:score] * s[:weight] }
      weighted_score.round(1)
    end

    # Simplified implementations for complex calculations
    # In production, these would have full implementations
    
    def calculate_net_revenue_retention
      115.0 # Placeholder - indicates revenue expansion from existing customers
    end

    def calculate_gross_revenue_retention
      85.0 # Placeholder - percentage of revenue retained before expansion
    end

    def calculate_revenue_concentration
      # Analyze revenue concentration in top customers
      25.0 # Placeholder - percentage of revenue from top 10% customers
    end

    def analyze_revenue_by_plan
      Plan.joins(:subscriptions)
        .where(subscriptions: { status: 'active' })
        .group('plans.name')
        .sum('plans.monthly_price')
    end

    def calculate_expansion_revenue
      # Revenue from upsells, cross-sells, and plan upgrades
      1500 # Placeholder
    end

    def perform_cohort_retention_analysis
      # Analyze retention by customer cohort
      { '2024-01' => 85, '2024-02' => 87, '2024-03' => 89 } # Placeholder
    end

    def calculate_trial_conversion_rate
      trial_users = User.joins(:subscription)
        .where.not(subscriptions: { trial_end: nil })
        .where(created_at: @date_range)
        .count
      
      return 0 if trial_users == 0
      
      converted_trials = User.joins(:subscription)
        .where.not(subscriptions: { trial_end: nil })
        .where(subscriptions: { status: 'active' })
        .where(created_at: @date_range)
        .count
      
      (converted_trials.to_f / trial_users * 100).round(2)
    end

    def calculate_arpu
      calculate_revenue_per_customer
    end

    def calculate_gross_margin
      # Simplified gross margin calculation
      # Would need actual cost of goods sold data
      72.0 # Placeholder percentage
    end

    def calculate_pmf_score
      # Product-Market Fit score
      75.0 # Placeholder
    end

    def assess_revenue_health(revenue_metrics)
      growth_rate = revenue_metrics[:revenue_growth_rate]
      
      case growth_rate
      when 20.. then 'excellent'
      when 10..19 then 'good'
      when 0..9 then 'fair'
      else 'poor'
      end
    end

    def assess_customer_health(customer_metrics)
      ltv_cac = customer_metrics[:ltv_cac_ratio]
      churn_rate = customer_metrics[:customer_churn_rate]
      
      if ltv_cac > 3 && churn_rate < 5
        'excellent'
      elsif ltv_cac > 2 && churn_rate < 8
        'good'
      elsif ltv_cac > 1.5 && churn_rate < 12
        'fair'
      else
        'poor'
      end
    end

    def assess_growth_health(growth_metrics)
      growth_rate = growth_metrics[:overall_growth_rate]
      
      case growth_rate
      when 25.. then 'excellent'
      when 15..24 then 'good'
      when 5..14 then 'fair'
      else 'poor'
      end
    end

    def assess_profitability_health(profitability_metrics)
      gross_margin = profitability_metrics[:gross_margin]
      
      case gross_margin
      when 70.. then 'excellent'
      when 50..69 then 'good'
      when 30..49 then 'fair'
      else 'poor'
      end
    end

    # Placeholder methods for complex calculations
    def calculate_mrr_at_date(date)
      calculate_monthly_recurring_revenue # Simplified
    end

    def count_active_subscriptions
      Subscription.active.count
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
        created_at: ..previous_period.end,
        status: 'active'
      ).count
      
      return 0 if previous_subs == 0
      
      ((current_subs - previous_subs).to_f / previous_subs * 100).round(2)
    end

    def analyze_plan_distribution
      Subscription.active.joins(:plan).group('plans.name').count
    end

    def assess_revenue_health_score(revenue_metrics)
      85.0 # Placeholder
    end

    def assess_customer_health_score(customer_metrics)
      78.0 # Placeholder
    end

    def assess_growth_health_score(growth_metrics)
      82.0 # Placeholder
    end

    def assess_profitability_health_score(profitability_metrics)
      75.0 # Placeholder
    end

    def identify_key_achievements(metrics)
      ['Strong revenue growth', 'Improved customer retention', 'Healthy unit economics']
    end

    def identify_priority_areas(metrics)
      ['Customer acquisition optimization', 'Churn reduction', 'Market expansion']
    end

    # Additional placeholder methods
    def calculate_acquisition_efficiency; 2.5; end
    def calculate_signup_conversion_rate; 15.0; end
    def calculate_revenue_churn_rate; 5.0; end
    def calculate_customer_retention_rate; 95.0; end
    def calculate_customer_health_score; 78.0; end
    def calculate_expansion_rate; 12.0; end
    def calculate_upsell_rate; 8.0; end
    def identify_cross_sell_opportunities; ['premium_features', 'additional_devices']; end
    def calculate_customer_success_metrics; { satisfaction: 4.2, nps: 45 }; end
    def calculate_plan_conversion_rates; {}; end
    def calculate_plan_churn_rates; {}; end
    def identify_most_popular_plans; ['starter', 'professional']; end
    def analyze_trial_durations; { average: 14, median: 12 }; end
    def calculate_freemium_metrics; { conversion_rate: 5.0 }; end
    def calculate_activation_rate; 75.0; end
    def calculate_arpa; calculate_arpu; end
    def analyze_subscription_lengths; { average: 18 }; end
    def analyze_pricing_efficiency; 'good'; end
    def calculate_contribution_margin; 65.0; end
    def calculate_operating_margin; 25.0; end
    def calculate_net_margin; 15.0; end
    def assess_unit_economics_health; 'healthy'; end
    def calculate_contribution_margin_per_customer; 45.0; end
    def perform_break_even_analysis; { months: 8 }; end
    def analyze_cost_structure; {}; end
    def analyze_margin_trends; 'improving'; end
    def analyze_profitability_by_segment; {}; end
    def analyze_profitability_by_plan; {}; end
    def calculate_cost_efficiency_metrics; {}; end
    def analyze_market_share_indicators; {}; end
    def assess_competitive_position; 'strong'; end
    def measure_brand_performance; {}; end
    def measure_customer_satisfaction; 4.2; end
    def analyze_feature_adoption; {}; end
    def analyze_customer_feedback; {}; end
    def assess_market_demand; 'high'; end
    def calculate_market_penetration; 5.0; end
    def identify_market_expansion_opportunities; []; end
    def analyze_geographic_performance; {}; end
    def analyze_vertical_markets; {}; end
    def calculate_overall_growth_rate; 15.0; end
    def calculate_customer_growth_rate; 12.0; end
    def analyze_growth_channels; {}; end
    def calculate_sustainable_growth_rate; 18.0; end
    def calculate_growth_efficiency; 1.2; end
    def calculate_growth_investment_roi; 3.5; end
    def calculate_viral_coefficient; 0.2; end
    def identify_primary_growth_drivers; []; end
    def identify_growth_bottlenecks; []; end
    def identify_growth_opportunities; []; end
    def assess_growth_strategy_effectiveness; 'effective'; end
    def calculate_customer_service_efficiency; 85.0; end
    def calculate_sales_efficiency; 2.1; end
    def calculate_marketing_efficiency; 3.2; end
    def calculate_product_development_efficiency; 75.0; end
    def calculate_employee_productivity; 110.0; end
    def assess_technology_utilization; 'good'; end
    def calculate_capital_efficiency; 1.8; end
    def calculate_time_to_value; 14; end
    def calculate_automation_rate; 65.0; end
    def calculate_business_error_rates; 2.1; end
    def measure_cycle_times; {}; end
    def calculate_quality_metrics; {}; end
    def generate_revenue_forecast; {}; end
    def generate_customer_forecast; {}; end
    def generate_growth_projections; {}; end
    def generate_profitability_projections; {}; end
    def generate_market_opportunity_forecast; {}; end
    def perform_risk_assessment; {}; end
    def perform_scenario_planning; {}; end
    def generate_strategic_recommendations; []; end
  end
end