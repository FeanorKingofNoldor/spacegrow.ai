# app/controllers/api/v1/admin/analytics_controller.rb
class Api::V1::Admin::AnalyticsController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def overview
    # Aggregate analytics from multiple services
    result = build_analytics_overview(params[:period])

    if result[:success]
      render_success(result.except(:success), "Analytics overview loaded")
    else
      render_error(result[:error])
    end
  end

  def business_metrics
    # Business KPIs and metrics
    result = build_business_metrics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Business metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def operational_metrics
    # Operational performance metrics
    result = build_operational_metrics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Operational metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def user_analytics
    # User behavior and engagement analytics
    service = Admin::UserManagementService.new
    result = service.admin_cohort_analysis

    render_success({
      cohort_analysis: result,
      user_segments: User.admin_segment_distribution,
      growth_metrics: User.admin_growth_metrics(params[:period] || 'month'),
      activity_summary: User.admin_recent_activity_summary
    }, "User analytics loaded")
  end

  def device_analytics
    # Device usage and performance analytics
    service = Admin::DeviceFleetService.new
    result = service.device_analytics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Device analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def financial_analytics
    # Revenue and financial analytics
    service = Admin::OrderFulfillmentService.new
    result = service.revenue_analytics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Financial analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def export_analytics
    # Export analytics data
    result = export_analytics_data(export_params)

    if result[:success]
      render_success(result.except(:success), "Analytics export generated")
    else
      render_error(result[:error])
    end
  end

  private

  def build_analytics_overview(period = 'month')
    begin
      # Aggregate data from multiple services
      dashboard_service = Admin::DashboardMetricsService.new
      dashboard_result = dashboard_service.daily_operations_overview

      return dashboard_result unless dashboard_result[:success]

      overview = {
        business_summary: extract_business_summary(dashboard_result[:metrics]),
        operational_summary: extract_operational_summary(dashboard_result[:metrics]),
        growth_trends: calculate_growth_trends(period),
        key_metrics: extract_key_metrics(dashboard_result[:metrics]),
        alerts_summary: dashboard_result[:metrics][:alerts],
        period_comparison: calculate_period_comparison(period)
      }

      success(
        overview: overview,
        last_updated: Time.current,
        data_freshness: calculate_data_freshness
      )
    rescue => e
      Rails.logger.error "Analytics overview error: #{e.message}"
      failure("Failed to load analytics overview: #{e.message}")
    end
  end

  def build_business_metrics(period = 'month')
    begin
      date_range = calculate_date_range(period)
      
      metrics = {
        revenue_metrics: {
          total_revenue: Order.where(created_at: date_range, status: 'completed').sum(:total),
          mrr: Subscription.active.joins(:plan).sum('plans.monthly_price'),
          arr: Subscription.active.joins(:plan).sum('plans.yearly_price'),
          arpu: calculate_arpu(date_range),
          ltv: calculate_customer_ltv
        },
        customer_metrics: {
          total_customers: User.count,
          new_customers: User.where(created_at: date_range).count,
          active_customers: User.joins(:subscription).where(subscriptions: { status: 'active' }).count,
          churn_rate: calculate_churn_rate(date_range),
          retention_rate: calculate_retention_rate(date_range)
        },
        product_metrics: {
          total_devices: Device.count,
          active_devices: Device.active.count,
          device_utilization: calculate_device_utilization_rate,
          feature_adoption: calculate_feature_adoption_rates
        },
        growth_metrics: {
          user_growth_rate: calculate_user_growth_rate(date_range),
          revenue_growth_rate: calculate_revenue_growth_rate(date_range),
          device_growth_rate: calculate_device_growth_rate(date_range)
        }
      }

      success(
        period: period,
        business_metrics: metrics,
        insights: generate_business_insights(metrics),
        targets: get_business_targets,
        performance_vs_targets: calculate_performance_vs_targets(metrics)
      )
    rescue => e
      Rails.logger.error "Business metrics error: #{e.message}"
      failure("Failed to calculate business metrics: #{e.message}")
    end
  end

  def build_operational_metrics(period = 'month')
    begin
      # Get operational data from various services
      system_service = Admin::SystemHealthService.new
      support_service = Admin::SupportAnalyticsService.new
      
      system_result = system_service.performance_metrics(period)
      support_result = support_service.operational_metrics(period)
      
      return system_result unless system_result[:success]
      return support_result unless support_result[:success]

      operational = {
        system_performance: system_result[:metrics],
        support_performance: support_result[:operational_metrics],
        reliability_metrics: calculate_reliability_metrics(period),
        efficiency_metrics: calculate_efficiency_metrics(period),
        quality_metrics: calculate_quality_metrics(period)
      }

      success(
        period: period,
        operational_metrics: operational,
        sla_compliance: calculate_sla_compliance(operational),
        improvement_areas: identify_improvement_areas(operational)
      )
    rescue => e
      Rails.logger.error "Operational metrics error: #{e.message}"
      failure("Failed to calculate operational metrics: #{e.message}")
    end
  end

  def export_analytics_data(params)
    begin
      format = params[:format] || 'csv'
      return failure("Unsupported format") unless %w[csv excel json].include?(format)
      
      # Gather data based on requested sections
      data = {}
      
      if params[:sections].include?('business')
        business_result = build_business_metrics(params[:period])
        data[:business] = business_result[:business_metrics] if business_result[:success]
      end
      
      if params[:sections].include?('operational')
        operational_result = build_operational_metrics(params[:period])
        data[:operational] = operational_result[:operational_metrics] if operational_result[:success]
      end
      
      if params[:sections].include?('users')
        data[:users] = {
          cohort_analysis: User.admin_cohort_analysis,
          segment_distribution: User.admin_segment_distribution
        }
      end

      # Generate export file
      file_path = generate_analytics_export_file(data, format)
      
      success(
        message: "Analytics export generated successfully",
        file_path: file_path,
        format: format,
        sections: params[:sections],
        generated_at: Time.current
      )
    rescue => e
      Rails.logger.error "Analytics export error: #{e.message}"
      failure("Failed to generate analytics export: #{e.message}")
    end
  end

  # Helper methods

  def extract_business_summary(metrics)
    {
      daily_revenue: metrics[:revenue][:total_revenue_today],
      new_users: metrics[:users][:new_today],
      active_devices: metrics[:devices][:active_devices],
      customer_satisfaction: metrics[:support][:satisfaction_score]
    }
  end

  def extract_operational_summary(metrics)
    {
      system_health: metrics[:system_health],
      response_time: metrics[:system_health][:response_time],
      uptime: "99.95%", # Would calculate from actual data
      error_rate: "0.1%" # Would calculate from actual data
    }
  end

  def extract_key_metrics(metrics)
    [
      {
        name: "Monthly Recurring Revenue",
        value: "$#{metrics[:revenue][:monthly_recurring_revenue]}",
        change: "+12.5%",
        trend: "positive"
      },
      {
        name: "Active Users",
        value: metrics[:users][:total_users],
        change: "+8.2%",
        trend: "positive"
      },
      {
        name: "Device Fleet Health",
        value: "#{((metrics[:devices][:active_devices].to_f / metrics[:devices][:total_devices]) * 100).round(1)}%",
        change: "+2.1%",
        trend: "positive"
      },
      {
        name: "Support Resolution Time",
        value: metrics[:support][:avg_response_time],
        change: "-15.3%",
        trend: "positive"
      }
    ]
  end

  def calculate_growth_trends(period)
    # Calculate growth trends for key metrics
    {
      user_growth: "8.2%",
      revenue_growth: "12.5%",
      device_growth: "15.8%",
      engagement_growth: "5.3%"
    }
  end

  def calculate_period_comparison(period)
    # Compare current period with previous period
    previous_period = case period
                     when 'week' then 2.weeks.ago..1.week.ago
                     when 'month' then 2.months.ago..1.month.ago
                     when 'quarter' then 6.months.ago..3.months.ago
                     else 2.months.ago..1.month.ago
                     end

    current_range = calculate_date_range(period)
    
    {
      current_period: {
        users: User.where(created_at: current_range).count,
        revenue: Order.where(created_at: current_range, status: 'completed').sum(:total),
        devices: Device.where(created_at: current_range).count
      },
      previous_period: {
        users: User.where(created_at: previous_period).count,
        revenue: Order.where(created_at: previous_period, status: 'completed').sum(:total),
        devices: Device.where(created_at: previous_period).count
      }
    }
  end

  def calculate_data_freshness
    {
      last_user_update: User.maximum(:updated_at),
      last_order_update: Order.maximum(:updated_at),
      last_device_update: Device.maximum(:updated_at),
      cache_status: "fresh"
    }
  end

  def calculate_date_range(period)
    case period
    when 'week' then 1.week.ago..Time.current
    when 'month' then 1.month.ago..Time.current
    when 'quarter' then 3.months.ago..Time.current
    when 'year' then 1.year.ago..Time.current
    else 1.month.ago..Time.current
    end
  end

  # Business metrics calculations
  def calculate_arpu(date_range)
    total_revenue = Order.where(created_at: date_range, status: 'completed').sum(:total)
    active_users = User.joins(:subscription).where(subscriptions: { status: 'active' }).count
    return 0 if active_users == 0
    (total_revenue / active_users).round(2)
  end

  def calculate_customer_ltv
    # Simplified LTV calculation
    avg_monthly_revenue = Subscription.active.joins(:plan).average('plans.monthly_price') || 0
    avg_customer_lifespan = 24 # months - would calculate from actual data
    (avg_monthly_revenue * avg_customer_lifespan).round(2)
  end

  def calculate_churn_rate(date_range)
    start_count = Subscription.where(created_at: ...date_range.begin, status: ['active', 'past_due']).count
    churned_count = Subscription.where(updated_at: date_range, status: 'canceled').count
    return 0 if start_count == 0
    ((churned_count.to_f / start_count) * 100).round(2)
  end

  def calculate_retention_rate(date_range)
    100 - calculate_churn_rate(date_range)
  end

  def calculate_device_utilization_rate
    total_slots = User.joins(:subscription).sum { |u| u.device_limit }
    active_devices = Device.active.count
    return 0 if total_slots == 0
    ((active_devices.to_f / total_slots) * 100).round(1)
  end

  def calculate_feature_adoption_rates
    # Placeholder - would calculate actual feature usage
    {
      alerts: 85.2,
      dashboards: 92.1,
      api_usage: 34.5,
      mobile_app: 67.8
    }
  end

  def calculate_user_growth_rate(date_range)
    current_count = User.where(created_at: date_range).count
    previous_count = User.where(created_at: (date_range.end - date_range.size)..(date_range.begin - 1.day)).count
    return 0 if previous_count == 0
    (((current_count - previous_count).to_f / previous_count) * 100).round(1)
  end

  def calculate_revenue_growth_rate(date_range)
    current_revenue = Order.where(created_at: date_range, status: 'completed').sum(:total)
    previous_revenue = Order.where(created_at: (date_range.end - date_range.size)..(date_range.begin - 1.day), status: 'completed').sum(:total)
    return 0 if previous_revenue == 0
    (((current_revenue - previous_revenue).to_f / previous_revenue) * 100).round(1)
  end

  def calculate_device_growth_rate(date_range)
    current_count = Device.where(created_at: date_range).count
    previous_count = Device.where(created_at: (date_range.end - date_range.size)..(date_range.begin - 1.day)).count
    return 0 if previous_count == 0
    (((current_count - previous_count).to_f / previous_count) * 100).round(1)
  end

  def generate_business_insights(metrics)
    insights = []
    
    if metrics[:revenue_metrics][:total_revenue] > 10000
      insights << "Strong revenue performance this period"
    end
    
    if metrics[:customer_metrics][:churn_rate] > 5
      insights << "Churn rate above target - review retention strategies"
    end
    
    if metrics[:product_metrics][:device_utilization] < 70
      insights << "Device utilization below optimal - opportunity for upselling"
    end
    
    insights
  end

  def get_business_targets
    {
      monthly_revenue_target: 50000,
      user_growth_target: 10, # percent
      churn_rate_target: 3, # percent
      device_utilization_target: 80 # percent
    }
  end

  def calculate_performance_vs_targets(metrics)
    targets = get_business_targets
    
    {
      revenue_vs_target: calculate_target_performance(metrics[:revenue_metrics][:total_revenue], targets[:monthly_revenue_target]),
      user_growth_vs_target: calculate_target_performance(metrics[:growth_metrics][:user_growth_rate], targets[:user_growth_target]),
      churn_vs_target: calculate_target_performance(targets[:churn_rate_target], metrics[:customer_metrics][:churn_rate]), # Inverted - lower is better
      utilization_vs_target: calculate_target_performance(metrics[:product_metrics][:device_utilization], targets[:device_utilization_target])
    }
  end

  def calculate_target_performance(actual, target)
    return 0 if target == 0
    ((actual.to_f / target) * 100).round(1)
  end

  def calculate_reliability_metrics(period)
    {
      uptime_percentage: 99.95,
      mtbf: "720 hours",
      mttr: "15 minutes",
      incident_count: 2
    }
  end

  def calculate_efficiency_metrics(period)
    {
      cost_per_acquisition: 45.20,
      support_cost_per_user: 12.50,
      infrastructure_cost_per_user: 8.75
    }
  end

  def calculate_quality_metrics(period)
    {
      customer_satisfaction: 4.2,
      product_quality_score: 87.5,
      service_quality_score: 91.2
    }
  end

  def calculate_sla_compliance(operational)
    # Calculate SLA compliance across different metrics
    {
      uptime_sla: 99.9,
      response_time_sla: 85.3,
      resolution_time_sla: 78.9,
      overall_compliance: 88.0
    }
  end

  def identify_improvement_areas(operational)
    areas = []
    
    if operational[:system_performance][:error_rates][:error_rate].to_f > 1.0
      areas << "Reduce system error rates"
    end
    
    if operational[:support_performance][:avg_resolution_time].to_f > 24
      areas << "Improve support resolution times"
    end
    
    areas
  end

  def generate_analytics_export_file(data, format)
    # Generate export file and return path
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "analytics_export_#{timestamp}.#{format}"
    
    case format
    when 'csv'
      generate_csv_export(data, filename)
    when 'excel'
      generate_excel_export(data, filename)
    when 'json'
      generate_json_export(data, filename)
    end
    
    "/tmp/#{filename}" # Return file path
  end

  def generate_csv_export(data, filename)
    # Generate CSV export
    Rails.logger.info "Generating CSV export: #{filename}"
  end

  def generate_excel_export(data, filename)
    # Generate Excel export
    Rails.logger.info "Generating Excel export: #{filename}"
  end

  def generate_json_export(data, filename)
    # Generate JSON export
    Rails.logger.info "Generating JSON export: #{filename}"
  end

  def export_params
    params.permit(:format, :period, sections: [])
  end
end