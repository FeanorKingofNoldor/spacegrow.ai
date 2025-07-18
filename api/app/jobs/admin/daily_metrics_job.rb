# app/jobs/admin/daily_metrics_job.rb
module Admin
  class DailyMetricsJob < ApplicationJob
    queue_as :admin_analytics

    def perform
      Rails.logger.info "🔄 [DailyMetricsJob] Starting daily metrics calculation"
      
      begin
        # Calculate and cache daily metrics for dashboard performance
        service = Admin::DashboardMetricsService.new
        result = service.daily_operations_overview
        
        if result[:success]
          # Cache the results for fast dashboard loading
          Rails.cache.write("admin:daily_metrics", result[:metrics], expires_in: 1.day)
          Rails.cache.write("admin:daily_summary", result[:summary], expires_in: 1.day)
          
          Rails.logger.info "✅ [DailyMetricsJob] Daily metrics calculated and cached successfully"
          
          # Check for any critical metrics that need alerts
          check_metrics_for_alerts(result[:metrics])
        else
          Rails.logger.error "❌ [DailyMetricsJob] Failed to calculate daily metrics: #{result[:error]}"
        end
      rescue => e
        Rails.logger.error "❌ [DailyMetricsJob] Error calculating daily metrics: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    private

    def check_metrics_for_alerts(metrics)
      notification_service = Admin::AdminNotificationService.new
      
      # Check for critical alerts based on metrics
      if metrics[:devices][:error_devices] > 10
        notification_service.send_critical_alert('device_errors_spike', {
          error_count: metrics[:devices][:error_devices],
          threshold: 10,
          message: "High number of devices in error state detected"
        })
      end
      
      if metrics[:revenue][:revenue_growth] < -10
        notification_service.send_warning_alert('revenue_decline', {
          growth_rate: metrics[:revenue][:revenue_growth],
          threshold: -10,
          message: "Significant revenue decline detected"
        })
      end
      
      if metrics[:users][:churn_risk] > 50
        notification_service.send_warning_alert('churn_risk_high', {
          churn_risk_count: metrics[:users][:churn_risk],
          threshold: 50,
          message: "High number of users at churn risk"
        })
      end
    end
  end
end