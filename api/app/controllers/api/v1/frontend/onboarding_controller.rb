# app/controllers/api/v1/frontend/onboarding_controller.rb
class Api::V1::Frontend::OnboardingController < Api::V1::Frontend::ProtectedController
  def choose_plan
    if current_user.active_subscription&.active?
      return render json: {
        status: 'error',
        message: 'User already has an active subscription'
      }, status: :unprocessable_entity
    end

    plans = Plan.all.order(:monthly_price)
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) }
      }
    }
  end

  def select_plan
    # ✅ FIXED: Validate plan and interval BEFORE processing
    plan = Plan.find_by(id: params[:plan_id])
    unless plan
      return render json: {
        status: 'error',
        message: 'Plan not found'
      }, status: :not_found
    end

    interval = params[:interval] || 'month'
    unless %w[month year].include?(interval)
      return render json: {
        status: 'error',
        message: 'Invalid billing interval. Must be "month" or "year".'
      }, status: :bad_request
    end

    # ✅ FIXED: Check for existing active subscription properly
    if current_user.active_subscription&.active?
      return render json: {
        status: 'error',
        message: 'User already has an active subscription'
      }, status: :unprocessable_entity
    end

    # Check if user already has this exact plan/interval combination
    if current_user.subscription&.plan == plan && current_user.subscription&.interval == interval
      return render json: {
        status: 'error',
        message: "You are already subscribed to the #{plan.name} plan with #{interval}ly billing."
      }, status: :unprocessable_entity
    end

    subscription = SubscriptionService.create_subscription(
      user: current_user,
      plan: plan,
      interval: interval
    )

    if subscription.persisted?
      message = if current_user.subscription&.persisted?
                  "Successfully switched to #{plan.name} plan!"
                else
                  "Welcome to XSpaceGrow! Your #{plan.name} plan is now active."
                end

      render json: {
        status: 'success',
        message: message,
        data: {
          subscription: subscription_json(subscription),
          user: user_json(current_user.reload)
        }
      }
    else
      render json: {
        status: 'error',
        message: "Couldn't activate your plan. Please try again.",
        errors: subscription.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def plan_json(plan)
    {
      id: plan.id,
      name: plan.name,
      description: plan.description,
      device_limit: plan.device_limit,
      monthly_price: plan.monthly_price,
      yearly_price: plan.yearly_price,
      features: plan.features
    }
  end

  def subscription_json(subscription)
    {
      id: subscription.id,
      plan: plan_json(subscription.plan),
      status: subscription.status,
      interval: subscription.interval,
      device_limit: subscription.device_limit,
      additional_device_slots: subscription.additional_device_slots,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      cancel_at_period_end: subscription.cancel_at_period_end,
      # ✅ FIXED: Show all devices with their activation status
      devices: subscription.user.devices.map { |device| 
        { 
          id: device.id, 
          name: device.name, 
          device_type: device.device_type&.name,
          status: device.status,
          needs_activation: device.status == 'pending'
        } 
      }
    }
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      role: user.role,
      created_at: user.created_at,
      devices_count: user.devices.count,
      active_devices_count: user.devices.where(status: 'active').count,
      pending_devices_count: user.devices.where(status: 'pending').count,
      subscription: user.subscription ? subscription_json(user.subscription) : nil
    }
  end
end