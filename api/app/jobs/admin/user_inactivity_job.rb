# app/jobs/admin/user_inactivity_job.rb
module Admin
  class UserInactivityJob < ApplicationJob
    queue_as :admin_analytics

    def perform
      Rails.logger.info "🔄 [UserInactivityJob] Analyzing user activity and churn risk"
      
      begin
        # Detect inactive users and potential churn
        inactive_analysis = analyze_user_inactivity
        churn_analysis = analyze_churn_risk
        
        # Cache results for admin dashboard
        Rails.cache.write("admin:user_inactivity", inactive_analysis, expires_in: 6.hours)
        Rails.cache.write("admin:churn_risk", churn_analysis, expires_in: 6.hours)
        
        # Send alerts if needed
        check_inactivity_alerts(inactive_analysis, churn_analysis)
        
        Rails.logger.info "✅ [UserInactivityJob] User inactivity analysis completed"
      rescue => e
        Rails.logger.error "❌ [UserInactivityJob] Error analyzing user inactivity: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    private

    def analyze_user_inactivity
      inactive_30_days = User.where(last_sign_in_at: ..30.days.ago)
      inactive_60_days = User.where(last_sign_in_at: ..60.days.ago)
      inactive_90_days = User.where(last_sign_in_at: ..90.days.ago)
      
      {
        inactive_30_days: inactive_30_days.count,
        inactive_60_days: inactive_60_days.count,
        inactive_90_days: inactive_90_days.count,
        never_logged_in: User.where(last_sign_in_at: nil).count,
        total_users: User.count,
        inactivity_rate_30: calculate_inactivity_rate(inactive_30_days.count),
        inactivity_rate_60: calculate_inactivity_rate(inactive_60_days.count),
        inactivity_rate_90: calculate_inactivity_rate(inactive_90_days.count)
      }
    end

    def analyze_churn_risk
      # Users with past due subscriptions
      past_due_users = User.joins(:subscription).where(subscriptions: { status: 'past_due' })
      
      # Users who haven't used devices recently
      inactive_device_users = User.joins(:devices)
                                 .where(devices: { last_connection: ..7.days.ago })
                                 .distinct
      
      # Users with failed payments
      failed_payment_users = User.joins(:orders)
                                .where(orders: { status: 'payment_failed', created_at: 7.days.ago.. })
                                .distinct
      
      {
        past_due_subscriptions: past_due_users.count,
        inactive_device_usage: inactive_device_users.count,
        recent_payment_failures: failed_payment_users.count,
        total_churn_risk: (past_due_users + inactive_device_users + failed_payment_users).uniq.count,
        churn_risk_rate: calculate_churn_risk_rate
      }
    end

    def calculate_inactivity_rate(inactive_count)
      total_users = User.count
      return 0 if total_users == 0
      ((inactive_count.to_f / total_users) * 100).round(2)
    end

    def calculate_churn_risk_rate
      total_active_users = User.joins(:subscription).where(subscriptions: { status: 'active' }).count
      churn_risk_users = User.churn_risk.count
      return 0 if total_active_users == 0
      ((churn_risk_users.to_f / total_active_users) * 100).round(2)
    end

    def check_inactivity_alerts(inactive_analysis, churn_analysis)
      notification_service = Admin::AdminNotificationService.new
      
      # Alert if inactivity rate is high
      if inactive_analysis[:inactivity_rate_30] > 40
        notification_service.send_warning_alert('user_inactivity_high', {
          inactivity_rate: inactive_analysis[:inactivity_rate_30],
          inactive_count: inactive_analysis[:inactive_30_days],
          threshold: 40,
          message: "High user inactivity rate detected"
        })
      end
      
      # Alert if churn risk is elevated
      if churn_analysis[:churn_risk_rate] > 15
        notification_service.send_warning_alert('churn_risk_elevated', {
          churn_risk_rate: churn_analysis[:churn_risk_rate],
          at_risk_count: churn_analysis[:total_churn_risk],
          threshold: 15,
          message: "Elevated churn risk detected"
        })
      end
      
      # Alert if many past due subscriptions
      if churn_analysis[:past_due_subscriptions] > 20
        notification_service.send_critical_alert('past_due_subscriptions_high', {
          past_due_count: churn_analysis[:past_due_subscriptions],
          threshold: 20,
          message: "High number of past due subscriptions"
        })
      end
    end
  end
end