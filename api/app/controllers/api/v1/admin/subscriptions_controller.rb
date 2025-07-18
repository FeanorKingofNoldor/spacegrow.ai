# app/controllers/api/v1/admin/subscriptions_controller.rb
class Api::V1::Admin::SubscriptionsController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    # Reuse existing subscription services with admin context
    result = list_all_subscriptions(filter_params)

    if result[:success]
      render_success(result.except(:success), "Subscriptions loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    subscription = Subscription.find(params[:id])
    result = subscription_detailed_view(subscription)

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
    result = admin_update_subscription_status(subscription, params[:status], params[:reason])

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
    
    # Use existing PlanChangeWorkflow but with admin override
    workflow = Billing::PlanChangeWorkflow.new(subscription.user)
    result = workflow.execute_plan_change(target_plan, params[:interval] || 'month', admin_override: true)

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Subscription or plan not found", [], 404)
  end

  def billing_analytics
    result = subscription_billing_analytics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Billing analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def churn_analysis
    result = subscription_churn_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "Churn analysis loaded")
    else
      render_error(result[:error])
    end
  end

  def payment_issues
    result = subscription_payment_issues(filter_params)

    if result[:success]
      render_success(result.except(:success), "Payment issues loaded")
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :plan_id, :created_after, :created_before, 
                  :page, :per_page, :sort_by, :sort_direction, :search)
  end

  def list_all_subscriptions(params)
    begin
      subscriptions = Subscription.includes(:user, :plan, :extra_device_slots)
      
      # Apply filters
      subscriptions = subscriptions.where(status: params[:status]) if params[:status].present?
      subscriptions = subscriptions.where(plan_id: params[:plan_id]) if params[:plan_id].present?
      subscriptions = subscriptions.where(created_at: params[:created_after]..) if params[:created_after].present?
      subscriptions = subscriptions.where(created_at: ..params[:created_before]) if params[:created_before].present?
      
      if params[:search].present?
        subscriptions = subscriptions.joins(:user).where(
          "users.email ILIKE ? OR subscriptions.id::text = ?",
          "%#{params[:search]}%", params[:search]
        )
      end
      
      # Apply sorting
      case params[:sort_by]
      when 'created_at'
        subscriptions = subscriptions.order(created_at: params[:sort_direction] == 'desc' ? :desc : :asc)
      when 'user_email'
        subscriptions = subscriptions.joins(:user).order("users.email #{params[:sort_direction] == 'desc' ? 'DESC' : 'ASC'}")
      when 'plan_name'
        subscriptions = subscriptions.joins(:plan).order("plans.name #{params[:sort_direction] == 'desc' ? 'DESC' : 'ASC'}")
      else
        subscriptions = subscriptions.order(created_at: :desc)
      end
      
      # Pagination
      page = params[:page]&.to_i || 1
      per_page = [params[:per_page]&.to_i || 25, 100].min
      paginated_subscriptions = subscriptions.page(page).per(per_page)
      
      {
        success: true,
        subscriptions: serialize_subscriptions_list(paginated_subscriptions),
        pagination: {
          current_page: page,
          per_page: per_page,
          total_pages: paginated_subscriptions.total_pages,
          total_count: paginated_subscriptions.total_count
        },
        summary: build_subscriptions_summary(subscriptions),
        filters: build_subscription_filter_options
      }
    rescue => e
      Rails.logger.error "Subscription listing error: #{e.message}"
      { success: false, error: "Failed to load subscriptions: #{e.message}" }
    end
  end

  def subscription_detailed_view(subscription)
    begin
      # Use existing billing services for detailed data
      slot_manager = Billing::DeviceSlotManager.new(subscription.user)
      state_manager = Billing::DeviceStateManager.new(subscription.user)
      
      {
        success: true,
        subscription: serialize_subscription_detail(subscription),
        user_info: serialize_user_info(subscription.user),
        device_management: {
          slot_usage: slot_manager.slot_summary,
          device_states: state_manager.device_states_summary,
          devices_by_state: state_manager.devices_by_state
        },
        billing_history: subscription_billing_history(subscription),
        plan_change_options: available_plan_changes(subscription),
        admin_actions: available_admin_actions(subscription)
      }
    rescue => e
      Rails.logger.error "Subscription detail error: #{e.message}"
      { success: false, error: "Failed to load subscription details: #{e.message}" }
    end
  end

  def admin_update_subscription_status(subscription, new_status, reason = nil)
    begin
      return { success: false, error: "Invalid status" } unless %w[active past_due canceled].include?(new_status)
      return { success: false, error: "Subscription is already #{new_status}" } if subscription.status == new_status
      
      old_status = subscription.status
      
      ActiveRecord::Base.transaction do
        subscription.update!(status: new_status)
        
        # Handle status-specific logic using existing services
        case new_status
        when 'past_due'
          handle_admin_suspension(subscription, reason)
        when 'active'
          handle_admin_reactivation(subscription)
        when 'canceled'
          handle_admin_cancellation(subscription, reason)
        end
        
        # Log admin action
        log_admin_subscription_action(subscription, 'status_change', {
          old_status: old_status,
          new_status: new_status,
          reason: reason,
          changed_by: current_admin_id
        })
      end
      
      {
        success: true,
        message: "Subscription status updated from #{old_status} to #{new_status}",
        subscription: serialize_subscription_detail(subscription.reload)
      }
    rescue => e
      Rails.logger.error "Subscription status update error: #{e.message}"
      { success: false, error: "Failed to update subscription status: #{e.message}" }
    end
  end

  def subscription_billing_analytics(period = 'month')
    begin
      date_range = calculate_date_range(period)
      
      analytics = {
        revenue_metrics: {
          total_mrr: Subscription.active.joins(:plan).sum('plans.monthly_price'),
          new_mrr: Subscription.where(created_at: date_range, status: 'active').joins(:plan).sum('plans.monthly_price'),
          churned_mrr: Subscription.where(updated_at: date_range, status: 'canceled').joins(:plan).sum('plans.monthly_price'),
          expansion_mrr: calculate_expansion_mrr(date_range)
        },
        subscription_metrics: {
          new_subscriptions: Subscription.where(created_at: date_range).count,
          canceled_subscriptions: Subscription.where(updated_at: date_range, status: 'canceled').count,
          reactivated_subscriptions: Subscription.where(updated_at: date_range, status: 'active').where.not(created_at: date_range).count,
          past_due_subscriptions: Subscription.past_due.count
        },
        plan_distribution: Subscription.active.joins(:plan).group('plans.name').count,
        churn_rate: calculate_churn_rate(date_range)
      }
      
      {
        success: true,
        period: period,
        date_range: date_range,
        analytics: analytics
      }
    rescue => e
      Rails.logger.error "Billing analytics error: #{e.message}"
      { success: false, error: "Failed to generate billing analytics: #{e.message}" }
    end
  end

  def subscription_churn_analysis(params)
    begin
      churned_subscriptions = Subscription.where(status: 'canceled')
      
      if params[:created_after].present?
        churned_subscriptions = churned_subscriptions.where(updated_at: params[:created_after]..)
      end
      
      analysis = {
        total_churned: churned_subscriptions.count,
        churn_by_plan: churned_subscriptions.joins(:plan).group('plans.name').count,
        churn_by_tenure: analyze_churn_by_tenure(churned_subscriptions),
        churn_reasons: analyze_churn_reasons(churned_subscriptions),
        recovery_opportunities: identify_recovery_opportunities
      }
      
      {
        success: true,
        analysis: analysis,
        recent_churned: serialize_recent_churned(churned_subscriptions.recent.limit(20))
      }
    rescue => e
      Rails.logger.error "Churn analysis error: #{e.message}"
      { success: false, error: "Failed to analyze churn: #{e.message}" }
    end
  end

  def subscription_payment_issues(params)
    begin
      problem_subscriptions = Subscription.past_due
      failed_orders = Order.where(status: 'payment_failed', created_at: 7.days.ago..)
      
      analysis = {
        past_due_count: problem_subscriptions.count,
        total_at_risk_revenue: problem_subscriptions.joins(:plan).sum('plans.monthly_price'),
        payment_failure_trends: analyze_payment_failure_trends(failed_orders),
        recovery_actions: generate_recovery_actions(problem_subscriptions)
      }
      
      {
        success: true,
        analysis: analysis,
        problem_subscriptions: serialize_problem_subscriptions(problem_subscriptions.limit(50)),
        failed_payments: serialize_failed_payments(failed_orders.limit(50))
      }
    rescue => e
      Rails.logger.error "Payment issues analysis error: #{e.message}"
      { success: false, error: "Failed to analyze payment issues: #{e.message}" }
    end
  end

  # Helper methods

  def serialize_subscriptions_list(subscriptions)
    subscriptions.map do |sub|
      {
        id: sub.id,
        user_email: sub.user.email,
        plan_name: sub.plan&.name,
        status: sub.status,
        created_at: sub.created_at,
        monthly_cost: sub.monthly_cost,
        device_count: sub.user.devices.count,
        device_limit: sub.device_limit
      }
    end
  end

  def serialize_subscription_detail(subscription)
    {
      id: subscription.id,
      status: subscription.status,
      created_at: subscription.created_at,
      updated_at: subscription.updated_at,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      plan: subscription.plan ? serialize_plan(subscription.plan) : nil,
      monthly_cost: subscription.monthly_cost,
      extra_slots: subscription.active_extra_slots_count,
      total_extra_cost: subscription.total_extra_slot_cost
    }
  end

  def serialize_plan(plan)
    {
      id: plan.id,
      name: plan.name,
      device_limit: plan.device_limit,
      monthly_price: plan.monthly_price,
      yearly_price: plan.yearly_price
    }
  end

  def serialize_user_info(user)
    {
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      role: user.role,
      created_at: user.created_at,
      device_count: user.devices.count
    }
  end

  def build_subscriptions_summary(subscriptions_scope)
    {
      total_subscriptions: subscriptions_scope.count,
      by_status: subscriptions_scope.group(:status).count,
      by_plan: subscriptions_scope.joins(:plan).group('plans.name').count,
      total_mrr: subscriptions_scope.active.joins(:plan).sum('plans.monthly_price')
    }
  end

  def build_subscription_filter_options
    {
      statuses: Subscription.distinct.pluck(:status).compact,
      plans: Plan.pluck(:id, :name).map { |id, name| { id: id, name: name } }
    }
  end

  def handle_admin_suspension(subscription, reason)
    # Use existing DeviceStateManager to suspend devices
    state_manager = Billing::DeviceStateManager.new(subscription.user)
    state_manager.suspend_devices(subscription.user.devices.active.pluck(:id), reason: "admin_suspension: #{reason}")
  end

  def handle_admin_reactivation(subscription)
    # Use existing services to reactivate
    slot_manager = Billing::DeviceSlotManager.new(subscription.user)
    if slot_manager.can_activate_device?
      state_manager = Billing::DeviceStateManager.new(subscription.user)
      suspended_devices = subscription.user.devices.suspended.limit(slot_manager.available_slots)
      state_manager.wake_devices(suspended_devices.pluck(:id))
    end
  end

  def handle_admin_cancellation(subscription, reason)
    # Cancel subscription and suspend all devices
    state_manager = Billing::DeviceStateManager.new(subscription.user)
    state_manager.suspend_devices(subscription.user.devices.active.pluck(:id), reason: "subscription_canceled: #{reason}")
  end

  def subscription_billing_history(subscription)
    # Get billing history - this would integrate with your payment processor
    subscription.user.orders.order(created_at: :desc).limit(10).map do |order|
      {
        id: order.id,
        amount: order.total,
        status: order.status,
        created_at: order.created_at
      }
    end
  end

  def available_plan_changes(subscription)
    Plan.where.not(id: subscription.plan_id).map do |plan|
      {
        id: plan.id,
        name: plan.name,
        monthly_price: plan.monthly_price,
        device_limit: plan.device_limit,
        change_type: plan.device_limit > subscription.plan.device_limit ? 'upgrade' : 'downgrade'
      }
    end
  end

  def available_admin_actions(subscription)
    actions = []
    actions << 'change_status' unless subscription.canceled?
    actions << 'force_plan_change'
    actions << 'add_extra_slots'
    actions << 'send_notification'
    actions << 'view_devices'
    actions
  end

  def calculate_date_range(period)
    case period
    when 'week' then 1.week.ago..Time.current
    when 'month' then 1.month.ago..Time.current
    when 'quarter' then 3.months.ago..Time.current
    else 1.month.ago..Time.current
    end
  end

  def calculate_expansion_mrr(date_range)
    # Calculate MRR expansion from plan upgrades and extra slots
    plan_upgrades = Subscription.where(updated_at: date_range)
                               .joins(:plan)
                               .where.not(created_at: date_range)
                               .sum('plans.monthly_price')
    
    extra_slots = ExtraDeviceSlot.where(created_at: date_range, status: 'active').sum(:monthly_cost)
    
    plan_upgrades + extra_slots
  end

  def calculate_churn_rate(date_range)
    start_of_period = Subscription.where(created_at: ...date_range.begin, status: ['active', 'past_due']).count
    churned_in_period = Subscription.where(updated_at: date_range, status: 'canceled').count
    
    return 0 if start_of_period == 0
    ((churned_in_period.to_f / start_of_period) * 100).round(2)
  end

  def analyze_churn_by_tenure(churned_subscriptions)
    {
      'under_30_days' => churned_subscriptions.where('updated_at - created_at < ?', 30.days).count,
      '30_to_90_days' => churned_subscriptions.where('updated_at - created_at BETWEEN ? AND ?', 30.days, 90.days).count,
      'over_90_days' => churned_subscriptions.where('updated_at - created_at > ?', 90.days).count
    }
  end

  def analyze_churn_reasons(churned_subscriptions)
    # This would analyze cancellation reasons if you track them
    # For now, return placeholder data
    {
      'payment_failed' => churned_subscriptions.joins(:user).joins('LEFT JOIN orders ON orders.user_id = users.id AND orders.status = \'payment_failed\'').where.not('orders.id' => nil).distinct.count,
      'voluntary' => churned_subscriptions.count * 0.6, # Placeholder
      'other' => churned_subscriptions.count * 0.4 # Placeholder
    }
  end

  def identify_recovery_opportunities
    {
      past_due_recoverable: Subscription.past_due.where(updated_at: 7.days.ago..).count,
      failed_payment_retry: Order.where(status: 'payment_failed', created_at: 3.days.ago..).distinct.count(:user_id),
      inactive_but_paying: Subscription.active.joins(:user).where(users: { last_sign_in_at: ..30.days.ago }).count
    }
  end

  def analyze_payment_failure_trends(failed_orders)
    {
      total_failures: failed_orders.count,
      by_day: failed_orders.group_by_day(:created_at).count,
      by_amount: {
        'under_50' => failed_orders.where(total: ..50).count,
        '50_to_200' => failed_orders.where(total: 50..200).count,
        'over_200' => failed_orders.where(total: 200..).count
      }
    }
  end

  def generate_recovery_actions(problem_subscriptions)
    actions = []
    
    actions << {
      type: 'payment_retry',
      count: problem_subscriptions.count,
      description: 'Retry failed payments for past due subscriptions'
    }
    
    actions << {
      type: 'customer_outreach',
      count: problem_subscriptions.where(updated_at: 3.days.ago..).count,
      description: 'Contact customers with recent payment issues'
    }
    
    actions
  end

  def serialize_recent_churned(subscriptions)
    subscriptions.map do |sub|
      {
        id: sub.id,
        user_email: sub.user.email,
        plan_name: sub.plan&.name,
        canceled_at: sub.updated_at,
        tenure_days: (sub.updated_at - sub.created_at).to_i / 1.day
      }
    end
  end

  def serialize_problem_subscriptions(subscriptions)
    subscriptions.map do |sub|
      {
        id: sub.id,
        user_email: sub.user.email,
        plan_name: sub.plan&.name,
        past_due_since: sub.updated_at,
        monthly_value: sub.monthly_cost
      }
    end
  end

  def serialize_failed_payments(orders)
    orders.map do |order|
      {
        id: order.id,
        user_email: order.user.email,
        amount: order.total,
        failure_reason: order.payment_failure_reason,
        failed_at: order.created_at
      }
    end
  end

  def log_admin_subscription_action(subscription, action, metadata = {})
    Rails.logger.info "Admin Subscription Action: #{action} on subscription #{subscription.id} - #{metadata}"
  end

  def current_admin_id
    1 # Placeholder - implement based on your auth system
  end
end