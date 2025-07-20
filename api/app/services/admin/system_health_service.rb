# app/services/admin/system_health_service.rb
module Admin
  class SystemHealthService < ApplicationService
    def system_health_check
      begin
        health_checks = {
          database: check_database_health,
          redis: check_redis_health,
          sidekiq: check_sidekiq_health,
          storage: check_storage_health,
          external_apis: check_external_apis_health,
          memory: check_memory_usage,
          cpu: check_cpu_usage,
          disk: check_disk_usage
        }
        
        overall_status = determine_overall_health_status(health_checks)
        
        success(
          overall_status: overall_status,
          health_checks: health_checks,
          last_check: Time.current,
          summary: build_health_summary(health_checks),
          recommendations: generate_health_recommendations(health_checks),
          system_overview: build_system_overview,
          real_time_metrics: gather_real_time_metrics
        )
      rescue => e
        Rails.logger.error "System health check error: #{e.message}"
        failure("Failed to perform system health check: #{e.message}")
      end
    end

    # Simple performance overview with real data only
    def basic_performance_metrics
      begin
        metrics = {
          requests_per_minute: calculate_requests_per_minute,
          error_rate: calculate_current_error_rate,
          active_connections: get_active_connections_count,
          database_connections: check_database_health[:connection_pool_utilization],
          sidekiq_stats: get_sidekiq_basic_stats,
          system_resources: get_current_system_resources
        }
        
        success(
          metrics: metrics,
          timestamp: Time.current,
          status: determine_performance_status(metrics)
        )
      rescue => e
        Rails.logger.error "Performance metrics error: #{e.message}"
        failure("Failed to gather performance metrics: #{e.message}")
      end
    end

    private

    # ===== HEALTH CHECK METHODS =====
    
    def check_database_health
      begin
        start_time = Time.current
        ActiveRecord::Base.connection.execute("SELECT 1")
        response_time = ((Time.current - start_time) * 1000).round(2)
        
        connection_pool_size = ActiveRecord::Base.connection_pool.size
        active_connections = ActiveRecord::Base.connection_pool.connections.count
        
        {
          status: 'healthy',
          response_time_ms: response_time,
          connection_pool_usage: "#{active_connections}/#{connection_pool_size}",
          connection_pool_utilization: ((active_connections.to_f / connection_pool_size) * 100).round(1)
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message,
          response_time_ms: nil
        }
      end
    end

    def check_redis_health
      begin
        start_time = Time.current
        Rails.cache.write("health_check_#{Time.current.to_i}", "ok", expires_in: 1.minute)
        result = Rails.cache.read("health_check_#{Time.current.to_i}")
        response_time = ((Time.current - start_time) * 1000).round(2)
        
        {
          status: result == "ok" ? 'healthy' : 'unhealthy',
          response_time_ms: response_time,
          memory_usage: get_redis_memory_usage
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message,
          response_time_ms: nil
        }
      end
    end

    def check_sidekiq_health
      begin
        stats = Sidekiq::Stats.new
        queue_sizes = Sidekiq::Queue.all.map { |q| [q.name, q.size] }.to_h
        
        total_queued = stats.enqueued
        status = total_queued > 1000 ? 'warning' : 'healthy'
        status = 'unhealthy' if total_queued > 5000
        
        {
          status: status,
          enqueued_jobs: total_queued,
          processed_jobs: stats.processed,
          failed_jobs: stats.failed,
          retry_jobs: stats.retry_size,
          dead_jobs: stats.dead_size,
          queue_sizes: queue_sizes,
          processes: stats.processes_size,
          workers: stats.workers_size
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message
        }
      end
    end

    def check_storage_health
      begin
        disk_usage = get_disk_usage
        
        status = case disk_usage[:percentage]
                 when 0..80 then 'healthy'
                 when 81..90 then 'warning'
                 else 'critical'
                 end
        
        {
          status: status,
          disk_usage: disk_usage,
          tmp_directory: check_tmp_directory,
          log_directory: check_log_directory
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message
        }
      end
    end

    def check_external_apis_health
      apis = {
        stripe: check_stripe_api,
        # Add other external services as needed
      }
      
      overall_status = apis.values.all? { |api| api[:status] == 'healthy' } ? 'healthy' : 'degraded'
      
      {
        status: overall_status,
        apis: apis
      }
    end

    def check_memory_usage
      begin
        memory_info = get_system_memory_info
        
        status = case memory_info[:usage_percentage]
                 when 0..80 then 'healthy'
                 when 81..90 then 'warning'
                 else 'critical'
                 end
        
        {
          status: status,
          **memory_info
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message
        }
      end
    end

    def check_cpu_usage
      begin
        cpu_info = get_cpu_usage_info
        
        status = case cpu_info[:usage_percentage]
                 when 0..80 then 'healthy'
                 when 81..90 then 'warning'
                 else 'critical'
                 end
        
        {
          status: status,
          **cpu_info
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message
        }
      end
    end

    def check_disk_usage
      begin
        disk_info = get_disk_usage
        
        status = case disk_info[:percentage]
                 when 0..80 then 'healthy'
                 when 81..90 then 'warning'
                 else 'critical'
                 end
        
        {
          status: status,
          **disk_info
        }
      rescue => e
        {
          status: 'unhealthy',
          error: e.message
        }
      end
    end

    # ===== SYSTEM INFO METHODS =====
    
    def build_system_overview
      {
        uptime: calculate_system_uptime,
        version: Rails.application.class.module_parent_name,
        environment: Rails.env,
        ruby_version: RUBY_VERSION,
        rails_version: Rails::VERSION::STRING,
        total_users: User.count,
        total_devices: Device.count,
        active_sessions: UserSession.active.count
      }
    end

    def gather_real_time_metrics
      {
        requests_per_minute: calculate_requests_per_minute,
        error_rate: calculate_current_error_rate,
        active_connections: get_active_connections_count,
        memory_usage_percentage: get_system_memory_info[:usage_percentage],
        cpu_usage_percentage: get_cpu_usage_info[:usage_percentage]
      }
    end

    def get_sidekiq_basic_stats
      begin
        stats = Sidekiq::Stats.new
        {
          enqueued: stats.enqueued,
          processed: stats.processed,
          failed: stats.failed,
          processes: stats.processes_size,
          workers: stats.workers_size
        }
      rescue => e
        Rails.logger.error "Sidekiq stats failed: #{e.message}"
        { error: e.message }
      end
    end

    def get_current_system_resources
      {
        memory: get_system_memory_info,
        cpu: get_cpu_usage_info,
        disk: get_disk_usage
      }
    end

    # ===== STATUS DETERMINATION =====
    
    def determine_overall_health_status(health_checks)
      statuses = health_checks.values.map { |check| check[:status] }
      
      return 'critical' if statuses.include?('unhealthy')
      return 'warning' if statuses.include?('warning')
      return 'degraded' if statuses.include?('degraded')
      'healthy'
    end

    def determine_performance_status(metrics)
      return 'degraded' if metrics[:error_rate].to_f > 5.0
      return 'warning' if metrics[:requests_per_minute] > 10000
      'healthy'
    end

    def build_health_summary(health_checks)
      healthy_count = health_checks.values.count { |check| check[:status] == 'healthy' }
      total_count = health_checks.count
      
      {
        healthy_services: healthy_count,
        total_services: total_count,
        health_percentage: ((healthy_count.to_f / total_count) * 100).round(1),
        critical_issues: health_checks.select { |_, check| check[:status] == 'unhealthy' }.keys,
        warnings: health_checks.select { |_, check| check[:status] == 'warning' }.keys
      }
    end

    def generate_health_recommendations(health_checks)
      recommendations = []
      
      health_checks.each do |service, check|
        case check[:status]
        when 'unhealthy'
          recommendations << "URGENT: #{service} is unhealthy - #{check[:error] || 'requires immediate attention'}"
        when 'warning'
          recommendations << "WARNING: #{service} needs monitoring - performance degraded"
        when 'critical'
          recommendations << "CRITICAL: #{service} at capacity - immediate action required"
        end
      end
      
      recommendations
    end

    # ===== REAL DATA METHODS =====
    
    def get_redis_memory_usage
      begin
        redis_info = Rails.cache.redis.info
        memory_used = redis_info['used_memory_human']
        memory_used || "unknown"
      rescue => e
        Rails.logger.error "Redis memory check failed: #{e.message}"
        "unavailable"
      end
    end

    def get_disk_usage
      begin
        require 'sys/filesystem'
        stat = Sys::Filesystem.stat(Rails.root.to_s)
        
        total_gb = (stat.blocks * stat.fragment_size) / (1024**3)
        available_gb = (stat.blocks_available * stat.fragment_size) / (1024**3)
        used_gb = total_gb - available_gb
        percentage = ((used_gb.to_f / total_gb) * 100).round(1)
        
        {
          used: "#{used_gb.round(1)} GB",
          total: "#{total_gb.round(1)} GB", 
          available: "#{available_gb.round(1)} GB",
          percentage: percentage
        }
      rescue => e
        Rails.logger.error "Disk usage check failed: #{e.message}"
        { used: "unknown", total: "unknown", available: "unknown", percentage: 0 }
      end
    end

    def get_system_memory_info
      begin
        require 'vmstat'
        memory = Vmstat.memory
        
        total_gb = memory.pagesize * memory.wired / (1024**3)
        available_gb = memory.pagesize * memory.free / (1024**3) 
        used_gb = total_gb - available_gb
        usage_percentage = ((used_gb.to_f / total_gb) * 100).round(1)
        
        {
          used: "#{used_gb.round(1)} GB",
          total: "#{total_gb.round(1)} GB",
          available: "#{available_gb.round(1)} GB", 
          usage_percentage: usage_percentage
        }
      rescue => e
        Rails.logger.error "Memory check failed: #{e.message}"
        { used: "unknown", total: "unknown", available: "unknown", usage_percentage: 0 }
      end
    end

    def get_cpu_usage_info
      begin
        require 'vmstat'
        cpu = Vmstat.cpu
        load_avg = Vmstat.load_average
        
        {
          usage_percentage: ((cpu.user + cpu.system).to_f / cpu.total * 100).round(1),
          load_average: [load_avg.one_minute, load_avg.five_minutes, load_avg.fifteen_minutes],
          cores: Vmstat.cpu.length
        }
      rescue => e
        Rails.logger.error "CPU usage check failed: #{e.message}"
        { usage_percentage: 0, load_average: [0, 0, 0], cores: 1 }
      end
    end

    def check_tmp_directory
      begin
        tmp_path = Rails.root.join('tmp')
        size_mb = calculate_directory_size(tmp_path)
        
        { status: 'healthy', size: "#{size_mb} MB" }
      rescue => e
        { status: 'unhealthy', error: e.message }
      end
    end

    def check_log_directory
      begin
        log_path = Rails.root.join('log')
        size_mb = calculate_directory_size(log_path)
        
        status = size_mb > 1000 ? 'warning' : 'healthy'
        
        { status: status, size: "#{size_mb} MB" }
      rescue => e
        { status: 'unhealthy', error: e.message }
      end
    end

    def check_stripe_api
      begin
        start_time = Time.current
        Stripe::Account.retrieve
        response_time = ((Time.current - start_time) * 1000).round(2)
        
        { status: 'healthy', response_time_ms: response_time }
      rescue Stripe::AuthenticationError
        { status: 'unhealthy', error: 'Stripe authentication failed' }
      rescue Stripe::APIConnectionError => e
        { status: 'unhealthy', error: "Stripe connection failed: #{e.message}" }
      rescue => e
        { status: 'unhealthy', error: "Stripe API error: #{e.message}" }
      end
    end

    def calculate_system_uptime
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

    def get_active_connections_count
      ActiveRecord::Base.connection_pool.connections.count
    end

    # ===== YABEDA METRICS (TEST THESE) =====
    
    def calculate_requests_per_minute
      begin
        # WARNING: This might not work as expected - Yabeda counters reset on restart
        # You may need to store these in Redis or use a different approach
        api_requests = Yabeda.spacegrow.api_requests.values.sum
        api_requests.to_f
      rescue => e
        Rails.logger.error "Request counting failed: #{e.message}"
        0
      end
    end

    def calculate_current_error_rate
      begin
        total_requests = Yabeda.spacegrow.api_requests.values.sum
        error_requests = Yabeda.system.error_responses.values.sum
        
        return "0%" if total_requests == 0
        
        rate = (error_requests.to_f / total_requests * 100).round(2)
        "#{rate}%"
      rescue => e
        Rails.logger.error "Error rate calculation failed: #{e.message}"
        "unknown"
      end
    end

    # ===== HELPER METHODS =====
    
    def calculate_directory_size(path)
      size_bytes = 0
      Dir.glob(File.join(path, '**', '*')).each do |file|
        size_bytes += File.size(file) if File.file?(file)
      end
      (size_bytes / (1024.0 * 1024.0)).round(1)
    end
  end
end