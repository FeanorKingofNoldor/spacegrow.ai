# app/controllers/api/v1/admin/system_controller.rb
class Api::V1::Admin::SystemController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def health
    service = Admin::SystemHealthService.new
    result = service.system_health_check

    if result[:success]
      render_success(result.except(:success), "System health check completed")
    else
      render_error(result[:error])
    end
  end

  def performance
    service = Admin::SystemHealthService.new
    result = service.basic_performance_metrics

    if result[:success]
      render_success(result.except(:success), "Performance metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def monitoring
    service = Admin::SystemHealthService.new
    result = service.system_health_check

    if result[:success]
      render_success(result.except(:success), "System monitoring loaded")
    else
      render_error(result[:error])
    end
  end

  # Simple maintenance info - just basic system status
  def maintenance
    begin
      maintenance_info = {
        maintenance_mode: Rails.application.config.maintenance_mode || false,
        system_status: 'operational',
        last_deployment: Rails.application.config.deploy_time || 'unknown',
        next_maintenance: 'Not scheduled',
        uptime: calculate_uptime
      }

      render_success({ maintenance: maintenance_info }, "Maintenance status loaded")
    rescue => e
      Rails.logger.error "Maintenance status error: #{e.message}"
      render_error("Failed to get maintenance status")
    end
  end

  # Simple logs info - basic log directory status
  def logs
    begin
      log_info = {
        log_directory_status: check_log_directory_status,
        recent_log_summary: get_recent_log_summary,
        log_levels: get_current_log_levels
      }

      render_success({ logs: log_info }, "System logs status loaded")
    rescue => e
      Rails.logger.error "System logs error: #{e.message}"
      render_error("Failed to analyze system logs")
    end
  end

  # Simple alerts - basic health-based alerts
  def alerts
    begin
      service = Admin::SystemHealthService.new
      health_result = service.system_health_check
      
      if health_result[:success]
        alerts = generate_alerts_from_health_status(health_result)
        render_success({ alerts: alerts }, "System alerts loaded")
      else
        render_error("Failed to check system health for alerts")
      end
    rescue => e
      Rails.logger.error "System alerts error: #{e.message}"
      render_error("Failed to load system alerts")
    end
  end

  # Simple infrastructure - basic service status
  def infrastructure
    begin
      service = Admin::SystemHealthService.new
      health_result = service.system_health_check
      
      if health_result[:success]
        infrastructure = build_infrastructure_summary(health_result)
        render_success({ infrastructure: infrastructure }, "Infrastructure status loaded")
      else
        render_error("Failed to check infrastructure status")
      end
    rescue => e
      Rails.logger.error "Infrastructure status error: #{e.message}"
      render_error("Failed to check infrastructure status")
    end
  end

  # Simple diagnostics - run basic health checks
  def diagnostics
    begin
      service = Admin::SystemHealthService.new
      health_result = service.system_health_check
      performance_result = service.basic_performance_metrics
      
      diagnostics = {
        health_check: health_result[:success] ? 'passed' : 'failed',
        performance_check: performance_result[:success] ? 'passed' : 'failed',
        timestamp: Time.current,
        summary: build_diagnostics_summary(health_result, performance_result)
      }

      render_success({ diagnostics: diagnostics }, "System diagnostics completed")
    rescue => e
      Rails.logger.error "System diagnostics error: #{e.message}"
      render_error("Failed to run system diagnostics")
    end
  end

  private

  def filter_params
    params.permit(:level, :category, :time_range, :limit, :offset)
  end

  # Simple helper methods for the simplified endpoints
  
  def calculate_uptime
    begin
      uptime_seconds = Time.current - Rails.application.config.boot_time
      days = (uptime_seconds / 86400).to_i
      hours = ((uptime_seconds % 86400) / 3600).to_i  
      minutes = ((uptime_seconds % 3600) / 60).to_i
      "#{days} days, #{hours} hours, #{minutes} minutes"
    rescue
      "unknown"
    end
  end

  def check_log_directory_status
    begin
      log_path = Rails.root.join('log')
      if File.directory?(log_path)
        size_mb = calculate_directory_size(log_path)
        {
          status: size_mb > 1000 ? 'warning' : 'healthy',
          size: "#{size_mb} MB",
          path: log_path.to_s
        }
      else
        { status: 'error', message: 'Log directory not found' }
      end
    rescue => e
      { status: 'error', message: e.message }
    end
  end

  def get_recent_log_summary
    {
      info: "Log analysis not implemented - use external log aggregation tools",
      recommendation: "Consider integrating with ELK stack, Fluentd, or similar"
    }
  end

  def get_current_log_levels
    {
      rails: Rails.logger.level,
      environment: Rails.env,
      current_level: Rails.application.config.log_level || 'info'
    }
  end

  def generate_alerts_from_health_status(health_result)
    alerts = []
    
    if health_result[:health_checks]
      health_result[:health_checks].each do |service, check|
        case check[:status]
        when 'unhealthy'
          alerts << {
            severity: 'critical',
            service: service,
            message: "#{service.to_s.humanize} is unhealthy",
            details: check[:error],
            timestamp: Time.current
          }
        when 'warning'
          alerts << {
            severity: 'warning', 
            service: service,
            message: "#{service.to_s.humanize} performance degraded",
            timestamp: Time.current
          }
        end
      end
    end

    {
      active_alerts: alerts,
      total_count: alerts.count,
      critical_count: alerts.count { |a| a[:severity] == 'critical' },
      warning_count: alerts.count { |a| a[:severity] == 'warning' }
    }
  end

  def build_infrastructure_summary(health_result)
    {
      core_services: {
        database: health_result[:health_checks][:database][:status],
        cache: health_result[:health_checks][:redis][:status],
        background_jobs: health_result[:health_checks][:sidekiq][:status],
        storage: health_result[:health_checks][:storage][:status]
      },
      external_services: {
        stripe: health_result[:health_checks][:external_apis][:apis][:stripe][:status]
      },
      system_resources: {
        memory: health_result[:health_checks][:memory][:status],
        cpu: health_result[:health_checks][:cpu][:status],
        disk: health_result[:health_checks][:disk][:status]
      },
      overall_status: health_result[:overall_status]
    }
  end

  def build_diagnostics_summary(health_result, performance_result)
    issues = []
    
    if !health_result[:success]
      issues << "Health check failed"
    end
    
    if !performance_result[:success]
      issues << "Performance check failed"
    end

    if health_result[:success] && health_result[:overall_status] != 'healthy'
      issues << "System health status: #{health_result[:overall_status]}"
    end

    {
      issues_found: issues.count,
      issues: issues,
      status: issues.empty? ? 'all_systems_operational' : 'issues_detected',
      recommendation: issues.empty? ? 'System is running normally' : 'Review identified issues'
    }
  end

  def calculate_directory_size(path)
    size_bytes = 0
    Dir.glob(File.join(path, '**', '*')).each do |file|
      size_bytes += File.size(file) if File.file?(file)
    end
    (size_bytes / (1024.0 * 1024.0)).round(1)
  end
end