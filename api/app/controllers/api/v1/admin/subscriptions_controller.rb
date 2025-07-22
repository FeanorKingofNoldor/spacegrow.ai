# app/controllers/api/v1/admin/subscriptions_controller.rb - CLEAN VERSION
class Api::V1::Admin::SubscriptionsController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::SubscriptionListService.new(filter_params).call
    
    if result[:success]
      render_success(result.except(:success), "Subscriptions loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    subscription = Subscription.includes(:user, :plan, :extra_device_slots).find(params[:id])
    result = Admin::SubscriptionDetailService.new(subscription).call
    
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
    result = Admin::SubscriptionStatusUpdateService.new(
      subscription, 
      params[:status], 
      params[:reason]
    ).call
    
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
    
    result = Admin::SubscriptionPlanChangeService.new(
      subscription,
      target_plan,
      params[:interval] || 'month'
    ).call
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription or plan not found", [], 404)
  end

  def billing_overview
    # Simple billing overview instead of complex analytics
    subscription = Subscription.find(params[:id])
    
    overview = {
      subscription: {
        id: subscription.id,
        status: subscription.status,
        plan: subscription.plan&.name,
        monthly_cost: subscription.monthly_cost,
        device_limit: subscription.device_limit
      },
      user: {
        email: subscription.user.email,
        device_count: subscription.user.devices.count,
        orders_count: subscription.user.orders.count,
        total_spent: subscription.user.orders.where(status: 'completed').sum(:total)
      },
      recent_orders: subscription.user.orders.recent.limit(5).map do |order|
        {
          id: order.id,
          status: order.status,
          total: order.total,
          created_at: order.created_at
        }
      end
    }
    
    render_success(overview, "Billing overview loaded")
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription not found", [], 404)
  end

  def device_management
    subscription = Subscription.find(params[:id])
    user = subscription.user
    
    # Use existing billing services
    slot_manager = Billing::DeviceSlotManager.new(user)
    state_manager = Billing::DeviceStateManager.new(user)
    
    device_info = {
      slot_summary: slot_manager.slot_summary,
      device_states: state_manager.device_states_summary,
      devices: user.devices.includes(:device_type).map do |device|
        {
          id: device.id,
          name: device.name,
          status: device.status,
          device_type: device.device_type&.name,
          last_connection: device.last_connection
        }
      end
    }
    
    render_success(device_info, "Device management info loaded")
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription not found", [], 404)
  end

  # Simplified analytics (just what you need)
  def billing_analytics
    period = params[:period] || 'month'
    
    analytics = {
      period: period,
      subscription_metrics: {
        total_active: Subscription.where(status: 'active').count,
        total_past_due: Subscription.where(status: 'past_due').count,
        total_canceled: Subscription.where(status: 'canceled').count,
        mrr: Subscription.active.joins(:plan).sum('plans.monthly_price')
      },
      plan_distribution: Subscription.active.joins(:plan).group('plans.name').count,
      recent_changes: Subscription.where(updated_at: 1.week.ago..).count
    }
    
    render_success(analytics, "Billing analytics loaded")
  end

  def payment_issues
    issues = {
      past_due_subscriptions: Subscription.where(status: 'past_due').includes(:user, :plan).map do |sub|
        {
          id: sub.id,
          user_email: sub.user.email,
          plan_name: sub.plan&.name,
          amount_due: sub.monthly_cost,
          days_past_due: (Date.current - sub.current_period_end.to_date).to_i
        }
      end,
      failed_payments: Order.where(status: 'payment_failed', created_at: 1.week.ago..).includes(:user).map do |order|
        {
          id: order.id,
          user_email: order.user.email,
          amount: order.total,
          failed_at: order.updated_at
        }
      end
    }
    
    render_success(issues, "Payment issues loaded")
  end

  private

  def filter_params
    params.permit(:status, :plan_id, :created_after, :created_before, 
                  :page, :per_page, :search, :user_id)
  end
end