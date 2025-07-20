# app/services/admin/subscription_detail_service.rb
module Admin
  class SubscriptionDetailService < ApplicationService
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
        subscription_age_days: (Time.current - subscription.created_at).to_i / 1.day,
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
        devices_by_state: state_manager.devices_by_state,
        device_details: serialize_user_devices,
        fleet_health: calculate_fleet_health
      }
    end

    def build_billing_history
      orders = user.orders.order(created_at: :desc).limit(10)
      
      {
        recent_orders: serialize_orders(orders),
        payment_methods: serialize_payment_methods,
        billing_issues: identify_billing_issues,
        revenue_metrics: calculate_user_revenue_metrics
      }
    end

    def build_plan_change_options
      current_plan = subscription.plan
      available_plans = Plan.where.not(id: current_plan&.id).order(:monthly_price)
      
      {
        current_plan: {
          id: current_plan&.id,
          name: current_plan&.name,
          monthly_price: current_plan&.monthly_price,
          device_limit: current_plan&.device_limit
        },
        available_plans: available_plans.map do |plan|
          {
            id: plan.id,
            name: plan.name,
            monthly_price: plan.monthly_price,
            device_limit: plan.device_limit,
            upgrade: plan.monthly_price > (current_plan&.monthly_price || 0),
            cost_difference: plan.monthly_price - (current_plan&.monthly_price || 0)
          }
        end,
        can_change_plan: subscription.active?,
        pending_changes: subscription.pending_plan_change
      }
    end

    def build_admin_actions
      {
        can_update_status: !%w[disabled destroyed].include?(subscription.status),
        can_force_plan_change: subscription.active? || subscription.past_due?,
        can_add_device_slots: true,
        can_refund_orders: user.orders.where(status: 'completed', created_at: 30.days.ago..).any?,
        available_status_changes: calculate_available_status_changes,
        bulk_actions: %w[send_email add_note flag_account create_support_ticket]
      }
    end

    def build_risk_assessment
      risk_factors = user.admin_risk_factors
      
      {
        risk_level: determine_risk_level(risk_factors),
        risk_factors: risk_factors,
        risk_score: calculate_risk_score(risk_factors),
        churn_probability: calculate_churn_probability,
        recommended_actions: generate_risk_recommendations(risk_factors),
        fraud_indicators: analyze_fraud_indicators
      }
    end

    def build_activity_timeline
      user.admin_activity_timeline(10).map do |activity|
        {
          type: activity[:type],
          description: activity[:description],
          timestamp: activity[:timestamp].iso8601,
          details: activity[:details] || {},
          severity: determine_activity_severity(activity)
        }
      end
    end

    def serialize_user_devices
      user.devices.includes(:device_type).map do |device|
        device_summary = device.admin_summary
        
        {
          id: device.id,
          name: device.name,
          device_type: device.device_type.name,
          status: device.status,
          admin_summary: device_summary,
          health_status: device.admin_health_status,
          connection_status: device.admin_connection_status,
          last_connection: device.last_connection&.iso8601,
          uptime_estimate: device.admin_uptime_estimate,
          alert_level: device.admin_alert_level,
          created_at: device.created_at.iso8601
        }
      end
    end

    def serialize_orders(orders)
      orders.map do |order|
        {
          id: order.id,
          status: order.status,
          total: order.total,
          created_at: order.created_at.iso8601,
          payment_method: order.payment_method,
          payment_failure_reason: order.payment_failure_reason,
          line_items_count: order.line_items.count
        }
      end
    end

    def calculate_next_billing_date
      return nil unless subscription.active?
      subscription.current_period_end
    end

    def calculate_lifetime_value
      user.orders.where(status: 'completed').sum(:total)
    end

    def calculate_fleet_health
      devices = user.devices
      return 'no_devices' if devices.empty?
      
      total = devices.count
      healthy = devices.where(status: 'active').count
      
      health_percentage = (healthy.to_f / total * 100).round(1)
      
      case health_percentage
      when 80..100 then 'excellent'
      when 60..79 then 'good'
      when 40..59 then 'fair'
      when 20..39 then 'poor'
      else 'critical'
      end
    end

    def identify_billing_issues
      issues = []
      
      issues << 'past_due_payment' if subscription.past_due?
      issues << 'failed_recent_orders' if user.orders.where(status: 'payment_failed', created_at: 7.days.ago..).any?
      issues << 'expired_payment_method' if payment_method_expired?
      issues << 'high_failure_rate' if calculate_payment_failure_rate > 30
      
      issues
    end

    def calculate_user_revenue_metrics
      completed_orders = user.orders.where(status: 'completed')
      
      {
        total_revenue: completed_orders.sum(:total),
        average_order_value: completed_orders.average(:total)&.round(2) || 0,
        order_count: completed_orders.count,
        monthly_revenue: calculate_monthly_revenue,
        revenue_trend: calculate_revenue_trend
      }
    end

    def determine_risk_level(risk_factors)
      return 'high' if risk_factors.include?('payment_past_due') || risk_factors.include?('multiple_failed_orders')
      return 'medium' if risk_factors.include?('inactive_user') || risk_factors.include?('over_device_limit')
      'low'
    end

    def calculate_risk_score(risk_factors)
      base_score = 0
      base_score += 30 if risk_factors.include?('payment_past_due')
      base_score += 25 if risk_factors.include?('multiple_failed_orders')
      base_score += 15 if risk_factors.include?('inactive_user')
      base_score += 10 if risk_factors.include?('over_device_limit')
      base_score += 5 if risk_factors.include?('no_recent_activity')
      
      [base_score, 100].min
    end

    def calculate_churn_probability
      risk_factors = user.admin_risk_factors
      
      probability = 10 # Base 10%
      probability += 40 if risk_factors.include?('payment_past_due')
      probability += 30 if risk_factors.include?('multiple_failed_orders')
      probability += 20 if risk_factors.include?('inactive_user')
      probability += 15 if risk_factors.include?('over_device_limit')
      
      [probability, 90].min # Cap at 90%
    end

    def generate_risk_recommendations(risk_factors)
      recommendations = []
      
      recommendations << 'Contact for payment resolution' if risk_factors.include?('payment_past_due')
      recommendations << 'Investigate payment method issues' if risk_factors.include?('multiple_failed_orders')
      recommendations << 'Send re-engagement campaign' if risk_factors.include?('inactive_user')
      recommendations << 'Offer plan upgrade or device management' if risk_factors.include?('over_device_limit')
      recommendations << 'Standard customer health check' if recommendations.empty?
      
      recommendations
    end

    def analyze_fraud_indicators
      {
        suspicious_payment_patterns: check_suspicious_payment_patterns,
        multiple_failed_attempts: user.orders.where(status: 'payment_failed', created_at: 24.hours.ago..).count >= 3,
        unusual_device_activity: check_unusual_device_activity,
        fraud_score: calculate_fraud_score
      }
    end

    def calculate_available_status_changes
      current_status = subscription.status
      
      case current_status
      when 'active'
        %w[past_due canceled]
      when 'past_due'
        %w[active canceled]
      when 'canceled'
        %w[active]
      else
        []
      end
    end

    def determine_activity_severity(activity)
      case activity[:type]
      when 'payment_failure', 'device_error', 'subscription_canceled'
        'high'
      when 'device_suspended', 'plan_change', 'payment_retry'
        'medium'
      else
        'low'
      end
    end

    # Helper methods
    def serialize_payment_methods
      # This would integrate with your payment provider
      []
    end

    def payment_method_expired?
      # This would check with your payment provider
      false
    end

    def calculate_payment_failure_rate
      total_orders = user.orders.where(created_at: 30.days.ago..).count
      return 0 if total_orders == 0
      
      failed_orders = user.orders.where(status: 'payment_failed', created_at: 30.days.ago..).count
      (failed_orders.to_f / total_orders * 100).round(1)
    end

    def calculate_monthly_revenue
      monthly_orders = user.orders.where(status: 'completed', created_at: 1.month.ago..)
      monthly_orders.sum(:total)
    end

    def calculate_revenue_trend
      current_month = calculate_monthly_revenue
      previous_month = user.orders.where(
        status: 'completed', 
        created_at: 2.months.ago..1.month.ago
      ).sum(:total)
      
      return 'new' if previous_month == 0
      
      change = ((current_month - previous_month) / previous_month * 100).round(1)
      change > 0 ? 'increasing' : 'decreasing'
    end

    def check_suspicious_payment_patterns
      recent_failures = user.orders.where(status: 'payment_failed', created_at: 7.days.ago..)
      recent_failures.count >= 2 && recent_failures.map(&:payment_failure_reason).uniq.count >= 2
    end

    def check_unusual_device_activity
      devices = user.devices
      return false if devices.empty?
      
      # Check for unusual patterns
      rapid_registrations = devices.where(created_at: 24.hours.ago..).count >= 3
      simultaneous_errors = devices.where(status: 'error', updated_at: 1.hour.ago..).count >= 2
      
      rapid_registrations || simultaneous_errors
    end

    def calculate_fraud_score
      score = 0
      score += 25 if check_suspicious_payment_patterns
      score += 20 if check_unusual_device_activity
      score += 15 if user.orders.where(status: 'payment_failed', created_at: 24.hours.ago..).count >= 3
      score += 10 if calculate_payment_failure_rate > 50
      
      [score, 100].min
    end
  end
end