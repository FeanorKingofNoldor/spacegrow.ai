class Api::V1::Frontend::OnboardingController < Api::V1::Frontend::ProtectedController
  def choose_plan
    if current_user.subscription.present?
      return render json: {
        status: 'error',
        message: 'User already has a subscription'
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
    
    subscription = SubscriptionService.create_subscription(
      user: current_user,
      plan: plan,
      interval: params[:interval] || 'month'
    )

    if subscription.persisted?
      render json: {
        status: 'success',
        message: "Welcome to XSpaceGrow! Your #{plan.name} plan is now active.",
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
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end
    }
  end
end
