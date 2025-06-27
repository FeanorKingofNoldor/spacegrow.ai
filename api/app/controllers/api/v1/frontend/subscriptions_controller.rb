class Api::V1::Frontend::SubscriptionsController < Api::V1::Frontend::ProtectedController
  before_action :set_subscription, only: [:cancel, :add_device_slot, :remove_device_slot]

  def index
    plans = Plan.all
    current_subscription = current_user.subscription
    
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) },
        current_subscription: current_subscription ? subscription_json(current_subscription) : nil
      }
    }
  end

  def choose_plan
    if current_user.subscription&.active?
      return render json: {
        status: 'error',
        message: 'User already has an active subscription'
      }, status: :unprocessable_entity
    end

    plans = Plan.all
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) }
      }
    }
  end

  def select_plan
    plan = Plan.find(params[:plan_id])

    if current_user.subscription&.plan == plan
      return render json: {
        status: 'error',
        message: "You are already subscribed to the #{plan.name} plan."
      }, status: :unprocessable_entity
    end

    subscription = SubscriptionService.create_subscription(
      user: current_user,
      plan: plan,
      interval: params[:interval] || 'month'
    )

    if subscription.persisted?
      message = if current_user.subscription
                  "Successfully switched to #{plan.name} plan!"
                else
                  "Welcome to XSpaceGrow! Your #{plan.name} plan is now active."
                end

      render json: {
        status: 'success',
        message: message,
        data: {
          subscription: subscription_json(subscription)
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

  def cancel
    SubscriptionService.cancel_subscription(@subscription)
    render json: {
      status: 'success',
      message: 'Subscription canceled successfully'
    }
  end

  def add_device_slot
    if @subscription&.active?
      @subscription.increment!(:additional_device_slots)
      render json: {
        status: 'success',
        message: 'Successfully added an additional device slot.',
        data: {
          additional_device_slots: @subscription.additional_device_slots,
          device_limit: @subscription.device_limit
        }
      }
    else
      render json: {
        status: 'error',
        message: "You don't have an active subscription to modify."
      }, status: :unprocessable_entity
    end
  end

  def remove_device_slot
    device_id = params[:device_id]
    message = @subscription.remove_specific_device(device_id)

    render json: {
      status: 'success',
      message: message
    }
  rescue StandardError => e
    render json: {
      status: 'error',
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def set_subscription
    @subscription = current_user.subscription
    
    unless @subscription
      render json: {
        status: 'error',
        message: 'No subscription found'
      }, status: :not_found
    end
  end

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
      devices: subscription.devices.map { |device| { id: device.id, name: device.name } }
    }
  end
end
