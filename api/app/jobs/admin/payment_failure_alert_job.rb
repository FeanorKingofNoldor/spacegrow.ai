# app/jobs/admin/payment_failure_alert_job.rb
module Admin
  class PaymentFailureAlertJob < ApplicationJob
    queue_as :admin_monitoring

    def perform
      Rails.logger.info "🔄 [PaymentFailureAlertJob] Monitoring payment failures"
      
      begin
        # Monitor payment failures and send notifications
        recent_failures = Order.where(status: 'payment_failed', created_at: 1.hour.ago..Time.current)
        failure_count = recent_failures.count
        
        if failure_count > 0
          # Analyze failure patterns
          failure_analysis = analyze_payment_failures(recent_failures)
          
          # Determine alert level
          alert_level = determine_payment_alert_level(failure_count, failure_analysis)
          
          if alert_level != 'none'
            send_payment_failure_alert(alert_level, failure_count, failure_analysis)
          end
          
          Rails.logger.info "✅ [PaymentFailureAlertJob] Payment monitoring completed - #{failure_count} failures detected"
        else
          Rails.logger.info "✅ [PaymentFailureAlertJob] Payment monitoring completed - no failures detected"
        end
      rescue => e
        Rails.logger.error "❌ [PaymentFailureAlertJob] Error monitoring payment failures: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    private

    def analyze_payment_failures(failed_orders)
      {
        total_failures: failed_orders.count,
        failure_reasons: failed_orders.group(:payment_failure_reason).count,
        affected_revenue: failed_orders.sum(:total),
        unique_users: failed_orders.distinct.count(:user_id),
        avg_order_value: failed_orders.average(:total)&.round(2) || 0
      }
    end

    def determine_payment_alert_level(failure_count, analysis)
      case failure_count
      when 0..2
        'none'
      when 3..9
        'warning'
      when 10..19
        'critical'
      else
        'emergency'
      end
    end

    def send_payment_failure_alert(alert_level, failure_count, analysis)
      notification_service = Admin::AdminNotificationService.new
      
      alert_data = {
        failure_count: failure_count,
        affected_revenue: analysis[:affected_revenue],
        unique_users: analysis[:unique_users],
        failure_reasons: analysis[:failure_reasons],
        message: "#{failure_count} payment failures in the last hour"
      }
      
      case alert_level
      when 'warning'
        notification_service.send_warning_alert('payment_failures_moderate', alert_data)
      when 'critical'
        notification_service.send_critical_alert('payment_failures_high', alert_data)
      when 'emergency'
        notification_service.send_critical_alert('payment_failures_emergency', alert_data)
      end
    end
  end
end