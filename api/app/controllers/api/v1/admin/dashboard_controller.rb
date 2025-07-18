# app/controllers/api/v1/admin/dashboard_controller.rb
class Api::V1::Admin::DashboardController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    service = Admin::DashboardMetricsService.new
    result = service.daily_operations_overview

    if result[:success]
      render_success(result.except(:success), "Dashboard metrics loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def alerts
    service = Admin::DashboardMetricsService.new
    result = service.critical_alerts

    if result[:success]
      render_success(result.except(:success), "Critical alerts loaded")
    else
      render_error(result[:error])
    end
  end

  def metrics
    time_period = params[:period] || 'today'
    service = Admin::DashboardMetricsService.new
    result = service.time_period_metrics(time_period)

    if result[:success]
      render_success(result.except(:success), "Metrics for #{time_period} loaded")
    else
      render_error(result[:error])
    end
  end
end