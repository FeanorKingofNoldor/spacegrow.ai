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

  def analytics
    service = Admin::SupportAnalyticsService.new
    result = service.support_analytics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Support analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def trending_issues
    service = Admin::SupportAnalyticsService.new
    result = service.trending_issues_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "Trending issues loaded")
    else
      render_error(result[:error])
    end
  end

  def customer_satisfaction
    service = Admin::SupportAnalyticsService.new
    result = service.customer_satisfaction_metrics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Customer satisfaction metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def operational_metrics
    service = Admin::SupportAnalyticsService.new
    result = service.operational_metrics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Operational metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def escalation_analysis
    service = Admin::SupportAnalyticsService.new
    result = service.escalation_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "Escalation analysis loaded")
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :priority, :category, :created_after, :created_before, 
                  :assigned_to, :user_id, :page, :per_page, :sort_by, :sort_direction)
  end
end