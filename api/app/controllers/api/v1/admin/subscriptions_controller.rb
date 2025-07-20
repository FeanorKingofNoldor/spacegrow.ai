# app/controllers/api/v1/admin/subscriptions_controller.rb - REFACTORED
class Api::V1::Admin::SubscriptionsController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    service = Admin::SubscriptionListService.new(filter_params)
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Subscriptions loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    subscription = Subscription.find(params[:id])
    service = Admin::SubscriptionDetailService.new(subscription)
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Subscription details loaded")
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription not found", [], 404)
  end

  def update_status
    subscription = Subscription.find(params[:id])
    service = Admin::SubscriptionStatusUpdateService.new(
      subscription, 
      params[:status], 
      params[:reason]
    )
    result = service.call

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription not found", [], 404)
  end

  def force_plan_change
    subscription = Subscription.find(params[:id])
    target_plan = Plan.find(params[:plan_id])
    
    service = Admin::SubscriptionPlanChangeService.new(
      subscription,
      target_plan,
      params[:interval] || 'month'
    )
    result = service.call

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription or plan not found", [], 404)
  end

  def billing_analytics
    service = Admin::BillingAnalyticsService.new(params[:period])
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Billing analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def churn_analysis
    service = Admin::ChurnAnalysisService.new(filter_params)
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Churn analysis loaded")
    else
      render_error(result[:error])
    end
  end

  def payment_issues
    service = Admin::PaymentIssuesAnalysisService.new(filter_params)
    result = service.call

    if result[:success]
      render_success(result.except(:success), "Payment issues loaded")
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :plan_id, :created_after, :created_before, 
                  :page, :per_page, :sort_by, :sort_direction, :search,
                  :tenure_range, :period)
  end
end