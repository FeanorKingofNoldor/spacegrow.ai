# app/services/admin/subscription_detail_service.rb
module Admin
  class SubscriptionDetailService < ApplicationService
    # Extract magic numbers into configurable constants
    FRAUD_SCORE_WEIGHTS = {
      suspicious_payments: 25,
      unusual_device_activity: 20,
      recent_payment_failures: 15,
      high_failure_rate: 10
    }.freeze

    RISK_THRESHOLDS = {
      payment_failure_rate: 50,
      recent_failures_count: 2,
      rapid_registrations_count: 3,
      simultaneous_errors_count: 2,
      max_fraud_score: 100
    }.freeze

    TIME_WINDOWS = {
      recent_failures: 7.days,
      rapid_registrations: 24.hours,
      simultaneous_errors: 1.hour,
      recent_payment_failures: 24.hours
    }.freeze

    def initialize(subscription)
      @subscription = subscription
      @user = subscription.user
    end

    def call
      begin
        success(
          subscription: serialize_subscription_detail,
          user_info: serialize_user_info,
          device_management: build_device_management_data,
          billing_history: build_billing_history,
          plan_change_options: build_plan_change_options,
          admin_actions: build_admin_actions,
          risk_assessment: build_risk_assessment,
          activity_timeline: build_activity_timeline
        )
      rescue => e
        Rails.logger.error "Subscription detail error: #{e.message}"
        failure("Failed to load subscription details: #{e.message}")
      end
    end

    private

    attr_reader :subscription, :user

    def serialize_subscription_detail
      {
        id: subscription.id,
        status: subscription.status,
        plan_name: subscription.plan&.name,
        plan_id: subscription.plan_id,
        monthly_cost: subscription.monthly_cost,
        device_limit: subscription.device_limit,
        extra_device_slots: subscription.extra_device_slots.count,
        created_at: subscription.created_at.iso8601,
        updated_at: subscription.updated_at.iso8601,
        current_period_start: subscription.current_period_start&.iso8601,
        current_period_end: subscription.current_period_end&.iso8601,
        trial_end: subscription.trial_end&.iso8601,
        canceled_at: subscription.canceled_at&.iso8601,
        stripe_subscription_id: subscription.stripe_subscription_id,
        next_billing_date: calculate_next_billing_date,
        subscription_age_days: calculate_subscription_age_days,
        lifetime_value: calculate_lifetime_value
      }
    end

    def serialize_user_info
      # Leverage the rich User model admin methods
      user_summary = user.admin_summary
      
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        status: user.admin_status,
        created_at: user.created_at.iso8601,
        last_sign_in_at: user.last_sign_in_at&.iso8601,
        timezone: user.timezone,
        sign_in_count: user.sign_in_count,
        account_age_days: user_summary[:account_age_days],
        total_spent: user_summary[:total_spent],
        risk_factors: user.admin_risk_factors,
        financial_summary: user.admin_financial_summary
      }
    end

    def build_device_management_data
      # Use existing billing services for device management
      slot_manager = Billing::DeviceSlotManager.new(user)
      state_manager = Billing::DeviceStateManager.new(user)
      
      {
        slot_usage: slot_manager.slot_summary,
        device_states: state_manager.device_states_summary,
        total_devices: user.devices.count,
        active_devices: user.devices.where(status: 'active').count,
        inactive_devices: user.devices.where(status: 'inactive').count,
        device_utilization: calculate_device_utilization
      }
    end

    def build_billing_history
      # Use real order data
      orders = user.orders.includes(:line_items).order(created_at: :desc).limit(10)
      
      {
        recent_orders: orders.map do |order|
          {
            id: order.id,
            total: order.total,
            status: order.status,
            created_at: order.created_at.iso8601,
            payment_method: order.payment_method,
            line_items_count: order.line_items.count
          }
        end,
        total_orders: user.orders.count,
        total_spent: user.orders.where(status: 'completed').sum(:total),
        payment_failure_rate: calculate_payment_failure_rate,
        last_successful_payment: user.orders.where(status: 'completed').maximum(:created_at)&.iso8601
      }
    end

    def build_plan_change_options
      current_plan = subscription.plan
      return { available_plans: [], can_upgrade: false, can_downgrade: false } unless current_plan

      available_plans = Plan.where.not(id: current_plan.id).order(:monthly_price)
      
      {
        current_plan: {
          id: current_plan.id,
          name: current_plan.name,
          monthly_price: current_plan.monthly_price,
          device_limit: current_plan.device_limit
        },
        available_plans: available_plans.map do |plan|
          {
            id: plan.id,
            name: plan.name,
            monthly_price: plan.monthly_price,
            device_limit: plan.device_limit,
            is_upgrade: plan.monthly_price > current_plan.monthly_price,
            price_difference: plan.monthly_price - current_plan.monthly_price
          }
        end,
        can_upgrade: available_plans.exists?(['monthly_price > ?', current_plan.monthly_price]),
        can_downgrade: available_plans.exists?(['monthly_price < ?', current_plan.monthly_price])
      }
    end

    def build_admin_actions
      {
        can_cancel: subscription.status == 'active',
        can_reactivate: subscription.status == 'canceled' && subscription.canceled_at && subscription.canceled_at > 30.days.ago,
        can_suspend: subscription.status == 'active',
        can_change_plan: subscription.status == 'active',
        available_statuses: %w[active past_due canceled suspended],
        requires_payment_update: subscription.status == 'past_due'
      }
    end

    def build_risk_assessment
      {
        overall_risk_level: calculate_overall_risk_level,
        fraud_score: calculate_fraud_score,
        payment_risk: assess_payment_risk,
        usage_risk: assess_usage_risk,
        account_risk: assess_account_risk,
        risk_factors: identify_risk_factors,
        recommended_actions: generate_risk_recommendations
      }
    end

    def build_activity_timeline
      # Combine various activity sources
      activities = []
      
      # Subscription events
      activities << {
        type: 'subscription_created',
        timestamp: subscription.created_at.iso8601,
        description: "Subscription created for #{subscription.plan&.name} plan"
      }
      
      if subscription.canceled_at
        activities << {
          type: 'subscription_canceled',
          timestamp: subscription.canceled_at.iso8601,
          description: 'Subscription canceled'
        }
      end
      
      # Recent orders
      user.orders.recent.limit(5).each do |order|
        activities << {
          type: "order_#{order.status}",
          timestamp: order.created_at.iso8601,
          description: "Order #{order.status}: $#{order.total}"
        }
      end
      
      # Recent device activity
      user.devices.recently_updated.limit(3).each do |device|
        activities << {
          type: 'device_activity',
          timestamp: device.updated_at.iso8601,
          description: "Device '#{device.name}' status: #{device.status}"
        }
      end
      
      activities.sort_by { |a| a[:timestamp] }.reverse.first(20)
    end

    # Calculation methods with real implementations
    def calculate_next_billing_date
      return nil unless subscription.current_period_end
      
      case subscription.status
      when 'active'
        subscription.current_period_end.iso8601
      when 'past_due'
        # Next attempt typically 3-7 days after period end
        (subscription.current_period_end + 3.days).iso8601
      else
        nil
      end
    end

    def calculate_subscription_age_days
      (Time.current - subscription.created_at).to_i / 1.day
    end

    def calculate_lifetime_value
      # Real calculation based on subscription history and payments
      total_payments = user.orders.where(status: 'completed').sum(:total)
      months_active = calculate_subscription_age_days / 30.0
      
      return 0 if months_active.zero?
      
      monthly_average = total_payments / months_active
      
      # Project forward based on plan and retention
      projected_months = case subscription.status
                         when 'active' then 12 # Average customer lifecycle
                         when 'past_due' then 3
                         else 0
                         end
      
      total_payments + (monthly_average * projected_months)
    end

    def calculate_device_utilization
      total_devices = user.devices.count
      return 0 if total_devices.zero?
      
      active_devices = user.devices.where(status: 'active').count
      (active_devices.to_f / total_devices * 100).round(1)
    end

    def calculate_payment_failure_rate
      total_orders = user.orders.count
      return 0 if total_orders.zero?
      
      failed_orders = user.orders.where(status: 'payment_failed').count
      (failed_orders.to_f / total_orders * 100).round(1)
    end

    # Risk Assessment Methods with extracted constants
    def calculate_overall_risk_level
      fraud_score = calculate_fraud_score
      
      case fraud_score
      when 0..20 then 'low'
      when 21..50 then 'medium'
      when 51..75 then 'high'
      else 'critical'
      end
    end

    def calculate_fraud_score
      score = 0
      score += FRAUD_SCORE_WEIGHTS[:suspicious_payments] if check_suspicious_payment_patterns
      score += FRAUD_SCORE_WEIGHTS[:unusual_device_activity] if check_unusual_device_activity
      score += FRAUD_SCORE_WEIGHTS[:recent_payment_failures] if recent_payment_failures_excessive?
      score += FRAUD_SCORE_WEIGHTS[:high_failure_rate] if calculate_payment_failure_rate > RISK_THRESHOLDS[:payment_failure_rate]
      
      [score, RISK_THRESHOLDS[:max_fraud_score]].min
    end

    def check_suspicious_payment_patterns
      recent_failures = user.orders.where(
        status: 'payment_failed',
        created_at: TIME_WINDOWS[:recent_failures].ago..
      )
      
      failure_count = recent_failures.count
      unique_failure_reasons = recent_failures.distinct.count(:payment_failure_reason)
      
      failure_count >= RISK_THRESHOLDS[:recent_failures_count] && unique_failure_reasons >= 2
    end

    def check_unusual_device_activity
      devices = user.devices.includes(:device_sensors)
      return false if devices.empty?
      
      # Check for unusual patterns with proper time windows
      rapid_registrations = devices.where(
        created_at: TIME_WINDOWS[:rapid_registrations].ago..
      ).count >= RISK_THRESHOLDS[:rapid_registrations_count]
      
      simultaneous_errors = devices.where(
        status: 'error',
        updated_at: TIME_WINDOWS[:simultaneous_errors].ago..
      ).count >= RISK_THRESHOLDS[:simultaneous_errors_count]
      
      rapid_registrations || simultaneous_errors
    end

    def recent_payment_failures_excessive?
      user.orders.where(
        status: 'payment_failed',
        created_at: TIME_WINDOWS[:recent_payment_failures].ago..
      ).count >= 3
    end

    def assess_payment_risk
      {
        failure_rate: calculate_payment_failure_rate,
        recent_failures: recent_payment_failures_excessive?,
        past_due: subscription.status == 'past_due',
        risk_level: calculate_payment_failure_rate > 30 ? 'high' : 'low'
      }
    end

    def assess_usage_risk
      device_count = user.devices.count
      device_limit = subscription.device_limit || subscription.plan&.device_limit || 0
      
      {
        over_limit: device_count > device_limit,
        utilization_rate: calculate_device_utilization,
        inactive_devices: user.devices.where(status: 'inactive').count,
        risk_level: device_count > device_limit ? 'high' : 'low'
      }
    end

    def assess_account_risk
      {
        account_age_days: calculate_subscription_age_days,
        new_account: calculate_subscription_age_days < 30,
        sign_in_frequency: user.sign_in_count.to_f / (calculate_subscription_age_days + 1),
        risk_level: calculate_subscription_age_days < 7 ? 'high' : 'low'
      }
    end

    def identify_risk_factors
      factors = []
      factors << 'suspicious_payment_patterns' if check_suspicious_payment_patterns
      factors << 'unusual_device_activity' if check_unusual_device_activity
      factors << 'high_payment_failure_rate' if calculate_payment_failure_rate > 30
      factors << 'over_device_limit' if user.devices.count > (subscription.device_limit || 0)
      factors << 'new_account' if calculate_subscription_age_days < 30
      factors << 'past_due_status' if subscription.status == 'past_due'
      factors
    end

    def generate_risk_recommendations
      recommendations = []
      
      if check_suspicious_payment_patterns
        recommendations << 'Review payment methods and transaction history'
      end
      
      if check_unusual_device_activity
        recommendations << 'Monitor device registration and error patterns'
      end
      
      if subscription.status == 'past_due'
        recommendations << 'Contact customer about payment update'
      end
      
      if user.devices.count > (subscription.device_limit || 0)
        recommendations << 'Review device usage and consider plan upgrade'
      end
      
      if calculate_payment_failure_rate > 30
        recommendations << 'Verify payment method and billing information'
      end
      
      recommendations
    end
  end
end