# app/controllers/api/v1/admin/analytics_controller.rb - REFACTORED
class Api::V1::Admin::AnalyticsController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def overview
    service = Admin::AnalyticsOverviewService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Analytics overview loaded")
    else
      render_error(result[:error])
    end
  end

  def business_metrics
    service = Admin::BusinessMetricsService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Business metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def operational_metrics
    service = Admin::OperationalMetricsService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Operational metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def user_analytics
    # Leverage rich User model admin methods directly with proper service pattern
    service = Admin::UserAnalyticsService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "User analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def device_analytics
    service = Admin::DeviceAnalyticsService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Device analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def financial_analytics
    service = Admin::FinancialAnalyticsService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Financial analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def export_analytics
    service = Admin::AnalyticsExportService.new(export_params)
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Analytics export generated")
    else
      render_error(result[:error])
    end
  end

  private

  def export_params
    params.permit(:format, :period, :metrics, :email_to)
  end
end