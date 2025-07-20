# app/controllers/api/v1/admin/support_controller.rb
class Api::V1::Admin::SupportController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    service = Admin::SupportAnalyticsService.new
    result = service.support_overview(filter_params)

    if result[:success]
      render_success(result.except(:success), "Support overview loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def device_issues
    service = Admin::SupportAnalyticsService.new
    result = service.device_issues_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "Device issues analysis loaded")
    else
      render_error(result[:error])
    end
  end

  def payment_issues
    service = Admin::SupportAnalyticsService.new
    result = service.payment_issues_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "Payment issues analysis loaded")
    else
      render_error(result[:error])
    end
  end

  def insights
    service = Admin::SupportAnalyticsService.new
    result = service.system_insights(params[:period])

    if result[:success]
      render_success(result.except(:success), "System insights loaded")
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :priority, :category, :created_after, :created_before, 
                  :user_id, :page, :per_page, :sort_by, :sort_direction)
  end
end