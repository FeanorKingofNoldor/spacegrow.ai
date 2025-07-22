# app/controllers/api/v1/admin/subscriptions_controller.rb - SIMPLIFIED FOR STARTUP
class Api::V1::Admin::SubscriptionsController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::SubscriptionService.new.list_subscriptions(filter_params)
    
    if result[:success]
      render_success(result.except(:success), "Subscriptions loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    result = Admin::SubscriptionService.new.subscription_detail(params[:id])
    
    if result[:success]
      render_success(result.except(:success), "Subscription details loaded")
    else
      render_error(result[:error])
    end
  end

  def update_status
    result = Admin::SubscriptionService.new.update_subscription_status(
      params[:id], 
      params[:status], 
      params[:reason]
    )
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :plan_id, :user_id, :search, :page, :per_page)
  end
end