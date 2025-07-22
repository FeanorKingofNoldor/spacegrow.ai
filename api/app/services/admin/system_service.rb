# app/services/admin/system_service.rb
module Admin
  class SystemService < ApplicationService
    def monitoring_overview
      begin
        success(
          system_health: system_health_summary,
          monitoring_tools: monitoring_tools_status,
          performance_metrics: performance_overview,
          resource_usage: resource_usage_summary,
          recent_alerts: recent_system_alerts
        )
      rescue => e
        Rails.logger.error "Admin System Monitoring error: #{e.message}"
        failure("Failed to load system monitoring: #{e.message}")
      end
    end

    def detailed_health_check
      begin
        success(
          database: detailed_database_health,
          redis: detailed_redis_health,
          sidekiq: detailed_sidekiq_health,
          application: detailed_application_health,
          infrastructure: infrastructure_health,
          external_services: external_services_health
        )
      rescue => e
        Rails.logger.error "Admin Detailed Health Check error: #{e.message}"
        failure("Failed to perform health check: #{e.message}")
      end
    end

    def performance_metrics
      begin
        success(
          response_times: get_response_time_metrics,
          error_rates: get_error_rate_metrics,
          throughput: get_throughput_metrics,
          resource_trends: get_resource_trends
        )
      rescue => e
        Rails.logger.error "Admin Performance Metrics error: #{e.message}"
        failure("Failed to load performance metrics: #{e.message}")
      end
    end

    def system_logs_summary
      begin
        success(
          error_logs: analyze_error_logs,
          slow_requests: analyze_slow_requests,
          device_logs: analyze_device_connection_logs,
          security_events: analyze_security_logs
        )
      rescue => e
        Rails.logger.error "Admin System Logs error: #{e.message}"
        failure("Failed to analyze system logs: #{e.message}")
      end
    end

    private

    def system_health_summary
      {
        overall_status: calculate_overall_health_status,
        database: quick_database_health,
        redis: quick_redis_health,
        sidekiq: quick_sidekiq_health,
        disk_space: get_disk_usage,
        memory: get_memory_usage,
        last_checked: Time.current
      }
    end

    def monitoring_tools_status
      {
        pghero: {
          name: 'Database Performance (PgHero)',
          url: '/admin/pghero',
          status: check_pghero_availability,
          description: 'Database performance monitoring, slow queries, index usage',
          quick_stats: get_pghero_quick_stats
        },
        sidekiq: {
          name: 'Background Jobs (Sidekiq Web)',
          url: '/admin/sidekiq',
          status: check_sidekiq_web_availability,
          description: 'Background job monitoring, queue management, failures',
          quick_stats: get_sidekiq_quick_stats
        },
        health_check: {
          name: 'System Health Checks',
          url: '/health_check',
          status: 'active',
          description: 'Basic system health validation',
          quick_stats: get_health_check_stats
        },
        prometheus: {
          name: 'IoT Metrics (Prometheus)',
          url: '/metrics',
          status: check_prometheus_availability,
          description: 'Custom IoT device metrics and business KPIs',
          quick_stats: get_prometheus_quick_stats
        },
        sentry: {
          name: 'Error Tracking (Sentry)',
          url: get_sentry_dashboard_url,
          status: check_sentry_availability,
          description: 'Application error tracking and performance monitoring',
          quick_stats: get_sentry_quick_stats
        }
      }
    end

    def performance_overview
      {
        avg_response_time: calculate_avg_response_time,
        error_rate_24h: calculate_error_rate,
        requests_per_minute: calculate_requests_per_minute,
        active_connections: get_active_connections,
        memory_usage_trend: get_memory_trend,
        cpu_usage: get_cpu_usage
      }
    end

    def resource_usage_summary
      {
        disk: {
          usage_percent: get_disk_usage_percent,
          free_space_gb: get_free_disk_space,
          status: get_disk_status
        },
        memory: {
          usage_mb: get_memory_usage_mb,
          usage_percent: get_memory_usage_percent,
          status: get_memory_status
        },
        cpu: {
          usage_percent: get_cpu_usage_percent,
          load_average: get_load_average,
          status: get_cpu_status
        }
      }
    end

    def recent_system_alerts
      alerts = []
      
      # Database alerts
      db_connections = get_database_connection_count
      if db_connections > 80
        alerts << {
          type: 'warning',
          source: 'database',
          message: "High database connection count: #{db_connections}",
          action: 'Check PgHero for connection details',
          url: '/admin/pghero'
        }
      end
      
      # Sidekiq alerts
      queue_size = get_sidekiq_queue_size
      if queue_size > 100
        alerts << {
          type: 'error',
          source: 'sidekiq',
          message: "Sidekiq queue backed up: #{queue_size} jobs",
          action: 'Check Sidekiq Web for details',
          url: '/admin/sidekiq'
        }
      end
      
      # Resource alerts
      disk_usage = get_disk_usage_percent
      if disk_usage > 85
        alerts << {
          type: 'critical',
          source: 'system',
          message: "Low disk space: #{disk_usage}% used",
          action: 'Free up disk space immediately'
        }
      end
      
      memory_usage = get_memory_usage_percent
      if memory_usage > 90
        alerts << {
          type: 'warning',
          source: 'system',
          message: "High memory usage: #{memory_usage}%",
          action: 'Monitor application memory leaks'
        }
      end
      
      alerts
    end

    # === DETAILED HEALTH CHECKS ===

    def detailed_database_health
      begin
        connection = ActiveRecord::Base.connection
        
        {
          status: 'healthy',
          connection_count: connection.execute("SELECT count(*) FROM pg_stat_activity").first['count'],
          database_size: get_database_size,
          slow_queries: get_slow_query_count,
          locks: get_database_lock_count,
          replication_lag: get_replication_lag,
          vacuum_stats: get_vacuum_statistics
        }
      rescue => e
        {
          status: 'error',
          error: e.message,
          connection_count: 0
        }
      end
    end

    def detailed_redis_health
      begin
        info = $redis.info
        
        {
          status: determine_redis_status(info),
          memory_usage_mb: (info['used_memory'].to_f / 1024 / 1024).round(2),
          memory_peak_mb: (info['used_memory_peak'].to_f / 1024 / 1024).round(2),
          connected_clients: info['connected_clients'],
          total_commands_processed: info['total_commands_processed'],
          keyspace_hits: info['keyspace_hits'],
          keyspace_misses: info['keyspace_misses'],
          hit_rate: calculate_redis_hit_rate(info)
        }
      rescue => e
        {
          status: 'error',
          error: e.message
        }
      end
    end

    def detailed_sidekiq_health
      begin
        stats = Sidekiq::Stats.new
        
        {
          status: determine_sidekiq_status(stats),
          processed: stats.processed,
          failed: stats.failed,
          enqueued: stats.enqueued,
          retry_size: stats.retry_size,
          dead_size: stats.dead_size,
          processes: stats.processes_size,
          workers_size: stats.workers_size,
          queues: get_queue_sizes
        }
      rescue => e
        {
          status: 'error',
          error: e.message
        }
      end
    end

    def detailed_application_health
      {
        rails_version: Rails::VERSION::STRING,
        ruby_version: RUBY_VERSION,
        environment: Rails.env,
        uptime: get_application_uptime,
        thread_count: Thread.list.count,
        memory_usage: get_app_memory_usage,
        gc_stats: get_garbage_collection_stats
      }
    end

    def infrastructure_health
      {
        disk_io: get_disk_io_stats,
        network_io: get_network_io_stats,
        system_load: get_system_load,
        process_count: get_process_count,
        open_files: get_open_files_count
      }
    end

    def external_services_health
      services = {}
      
      # Check Sentry connectivity
      if sentry_configured?
        services[:sentry] = check_sentry_connectivity
      end
      
      # Check other external services as needed
      # services[:stripe] = check_stripe_connectivity if stripe_configured?
      
      services
    end

    # === QUICK HEALTH CHECKS ===

    def quick_database_health
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        'healthy'
      rescue
        'error'
      end
    end

    def quick_redis_health
      begin
        $redis.ping
        'healthy'
      rescue
        'error'
      end
    end

    def quick_sidekiq_health
      begin
        queue_size = Sidekiq::Queue.new.size
        case queue_size
        when 0..50 then 'healthy'
        when 51..100 then 'warning'
        else 'error'
        end
      rescue
        'error'
      end
    end

    def calculate_overall_health_status
      db_status = quick_database_health
      redis_status = quick_redis_health
      sidekiq_status = quick_sidekiq_health
      
      if [db_status, redis_status, sidekiq_status].include?('error')
        'critical'
      elsif [db_status, redis_status, sidekiq_status].include?('warning')
        'warning'
      else
        'healthy'
      end
    end

    # === RESOURCE USAGE METHODS ===

    def get_disk_usage_percent
      begin
        stat = Sys::Filesystem.stat('/')
        ((stat.bytes_used.to_f / stat.bytes_total) * 100).round(1)
      rescue => e
        Rails.logger.warn "Could not get disk usage: #{e.message}"
        0
      end
    end

    def get_memory_usage_mb
      begin
        memory = Vmstat.memory
        (memory.active_bytes.to_f / 1024 / 1024).round(2)
      rescue => e
        Rails.logger.warn "Could not get memory usage: #{e.message}"
        0
      end
    end

    def get_memory_usage_percent
      begin
        memory = Vmstat.memory
        ((memory.active_bytes.to_f / memory.total_bytes) * 100).round(1)
      rescue => e
        Rails.logger.warn "Could not get memory percentage: #{e.message}"
        0
      end
    end

    def get_cpu_usage_percent
      begin
        # Simple CPU usage calculation
        vmstat = Vmstat.cpu
        vmstat.user + vmstat.system
      rescue => e
        Rails.logger.warn "Could not get CPU usage: #{e.message}"
        0
      end
    end

    # === TOOL AVAILABILITY CHECKS ===

    def check_pghero_availability
      defined?(PgHero) ? 'active' : 'unavailable'
    end

    def check_sidekiq_web_availability
      defined?(Sidekiq::Web) ? 'active' : 'unavailable'
    end

    def check_prometheus_availability
      defined?(Yabeda) ? 'active' : 'unavailable'
    end

    def check_sentry_availability
      sentry_configured? ? 'active' : 'not_configured'
    end

    def sentry_configured?
      Rails.application.credentials.dig(Rails.env.to_sym, :sentry, :dsn).present?
    end

    def get_sentry_dashboard_url
      if sentry_configured?
        "https://sentry.io/organizations/your-org/projects/"
      else
        nil
      end
    end

    # === PLACEHOLDER METHODS FOR FUTURE IMPLEMENTATION ===
    # These can be implemented as you add more monitoring

    def get_database_connection_count
      begin
        ActiveRecord::Base.connection.execute("SELECT count(*) FROM pg_stat_activity").first['count']
      rescue
        0
      end
    end

    def get_sidekiq_queue_size
      begin
        Sidekiq::Queue.new.size
      rescue
        0
      end
    end

    def get_pghero_quick_stats; { slow_queries: 0, connections: get_database_connection_count }; end
    def get_sidekiq_quick_stats; { enqueued: get_sidekiq_queue_size, failed: 0 }; end
    def get_health_check_stats; { status: 'passing' }; end
    def get_prometheus_quick_stats; { metrics_collected: 'active' }; end
    def get_sentry_quick_stats; { errors_24h: 'unknown' }; end
    
    # Placeholder implementations
    def calculate_avg_response_time; "150ms"; end
    def calculate_error_rate; 0.1; end
    def calculate_requests_per_minute; 120; end
    def get_active_connections; get_database_connection_count; end
    def get_memory_trend; "stable"; end
    def get_cpu_usage; 25.0; end
    def get_free_disk_space; 50.0; end
    def get_disk_status; "healthy"; end
    def get_memory_status; "healthy"; end
    def get_load_average; [0.5, 0.7, 0.8]; end
    def get_cpu_status; "healthy"; end
    def get_database_size; "Unknown"; end
    def get_slow_query_count; 0; end
    def get_database_lock_count; 0; end
    def get_replication_lag; "N/A"; end
    def get_vacuum_statistics; {}; end
    def determine_redis_status(info); "healthy"; end
    def calculate_redis_hit_rate(info); 95.0; end
    def determine_sidekiq_status(stats); "healthy"; end
    def get_queue_sizes; {}; end
    def get_application_uptime; "Unknown"; end
    def get_app_memory_usage; get_memory_usage_mb; end
    def get_garbage_collection_stats; {}; end
    def get_disk_io_stats; {}; end
    def get_network_io_stats; {}; end
    def get_system_load; get_load_average; end
    def get_process_count; 0; end
    def get_open_files_count; 0; end
    def check_sentry_connectivity; { status: "unknown" }; end
    def analyze_error_logs; { total_errors: 0 }; end
    def analyze_slow_requests; { slow_requests: 0 }; end
    def analyze_device_connection_logs; { connection_events: 0 }; end
    def analyze_security_logs; { security_events: 0 }; end
    def get_response_time_metrics; {}; end
    def get_error_rate_metrics; {}; end
    def get_throughput_metrics; {}; end
    def get_resource_trends; {}; end
    def get_disk_usage; { usage_percent: get_disk_usage_percent }; end
    def get_memory_usage; { usage_mb: get_memory_usage_mb }; end
  end
end