# app/jobs/admin/device_health_check_job.rb
module Admin
  class DeviceHealthCheckJob < ApplicationJob
    queue_as :admin_monitoring

    def perform
      Rails.logger.info "🔄 [DeviceHealthCheckJob] Starting device health monitoring"
      
      begin
        # Monitor device fleet health and generate automated alerts
        service = Admin::DeviceFleetService.new
        result = service.fleet_health_analysis('day')
        
        if result[:success]
          analysis = result[:analysis]
          
          # Check for device health issues
          check_device_health_alerts(analysis)
          
          # Update health metrics cache
          Rails.cache.write("admin:device_health", analysis, expires_in: 1.hour)
          
          Rails.logger.info "✅ [DeviceHealthCheckJob] Device health check completed successfully"
        else
          Rails.logger.error "❌ [DeviceHealthCheckJob] Failed to analyze device health: #{result[:error]}"
        end
      rescue => e
        Rails.logger.error "❌ [DeviceHealthCheckJob] Error in device health check: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    private

    def check_device_health_alerts(analysis)
      notification_service = Admin::AdminNotificationService.new
      
      # Check connection health
      if analysis[:connection_health][:connection_failures] > 20
        notification_service.send_warning_alert('device_connection_failures', {
          failure_count: analysis[:connection_health][:connection_failures],
          threshold: 20,
          message: "High device connection failure rate detected"
        })
      end
      
      # Check fleet alerts
      fleet_alerts = analysis[:alerts_summary]
      if fleet_alerts[:critical_alerts] > 5
        notification_service.send_critical_alert('device_fleet_critical', {
          critical_count: fleet_alerts[:critical_alerts],
          warning_count: fleet_alerts[:warning_alerts],
          message: "Multiple critical device issues detected"
        })
      end
      
      # Check performance degradation
      if analysis[:performance_metrics][:error_rates] > 5.0
        notification_service.send_warning_alert('device_performance_degraded', {
          error_rate: analysis[:performance_metrics][:error_rates],
          threshold: 5.0,
          message: "Device fleet error rate above threshold"
        })
      end
    end
  end
end