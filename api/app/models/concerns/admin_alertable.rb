# app/models/concerns/admin_alertable.rb
module AdminAlertable
  extend ActiveSupport::Concern

  included do
    after_create :check_admin_create_alerts
    after_update :check_admin_update_alerts
  end

  class_methods do
    def admin_alert_thresholds
      # Define alert thresholds per model
      case name
      when 'User'
        {
          inactive_days: 30,
          churn_risk_factors: 3,
          failed_payments: 3
        }
      when 'Device'
        {
          offline_hours: 1,
          error_state_hours: 2,
          no_connection_days: 1
        }
      when 'Order'
        {
          payment_failure_threshold: 5,
          processing_delay_hours: 24
        }
      else
        {}
      end
    end

    def admin_alert_conditions_met?
      # Check if any alert conditions are met for this model
      thresholds = admin_alert_thresholds
      
      case name
      when 'User'
        check_user_alert_conditions(thresholds)
      when 'Device'
        check_device_alert_conditions(thresholds)
      when 'Order'
        check_order_alert_conditions(thresholds)
      else
        false
      end
    end

    private

    def check_user_alert_conditions(thresholds)
      # Check for user-related alert conditions
      inactive_users = where(last_sign_in_at: ..thresholds[:inactive_days].days.ago).count
      churn_risk_users = joins(:subscription).where(subscriptions: { status: 'past_due' }).count
      
      inactive_users > 10 || churn_risk_users > 5
    end

    def check_device_alert_conditions(thresholds)
      # Check for device-related alert conditions
      offline_devices = where(last_connection: ..thresholds[:offline_hours].hours.ago).count
      error_devices = where(status: 'error').count
      
      offline_devices > 10 || error_devices > 5
    end

    def check_order_alert_conditions(thresholds)
      # Check for order-related alert conditions
      failed_payments = where(status: 'payment_failed', created_at: 1.hour.ago..).count
      failed_payments > thresholds[:payment_failure_threshold]
    end
  end

  # Instance methods for alerting
  def admin_should_alert?
    case self.class.name
    when 'User'
      user_alert_conditions?
    when 'Device'
      device_alert_conditions?
    when 'Order'
      order_alert_conditions?
    else
      false
    end
  end

  def admin_alert_data
    case self.class.name
    when 'User'
      {
        user_id: id,
        email: email,
        status: admin_status,
        risk_factors: admin_risk_factors,
        last_activity: last_sign_in_at
      }
    when 'Device'
      {
        device_id: id,
        name: name,
        status: status,
        last_connection: last_connection,
        owner_email: user.email
      }
    when 'Order'
      {
        order_id: id,
        status: status,
        total: total,
        customer_email: user.email,
        failure_reason: payment_failure_reason
      }
    else
      { id: id }
    end
  end

  private

  def check_admin_create_alerts
    # Check for alert conditions on create
    return unless admin_should_alert?
    
    Admin::AdminNotificationService.new.send_info_notification(
      "#{self.class.name.downcase}_created",
      admin_alert_data
    )
  end

  def check_admin_update_alerts
    # Check for alert conditions on update
    return unless admin_should_alert?
    
    Admin::AdminNotificationService.new.send_warning_alert(
      "#{self.class.name.downcase}_updated",
      admin_alert_data
    )
  end

  def user_alert_conditions?
    return false unless respond_to?(:admin_risk_factors)
    
    risk_factors = admin_risk_factors
    risk_factors.include?('payment_past_due') || 
    risk_factors.include?('multiple_failed_orders') ||
    (risk_factors.include?('inactive_user') && risk_factors.length > 1)
  end

  def device_alert_conditions?
    return false unless respond_to?(:last_connection)
    
    status == 'error' || 
    last_connection.nil? || 
    last_connection < 1.hour.ago
  end

  def order_alert_conditions?
    return false unless respond_to?(:status)
    
    status == 'payment_failed' && created_at > 1.hour.ago
  end
end