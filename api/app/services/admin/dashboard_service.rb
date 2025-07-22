# app/services/admin/dashboard_service.rb
module Admin
  class DashboardService < ApplicationService
    def call
      begin
        success(
          business: business_overview,
          devices: device_overview,
          system: system_overview,
          alerts: critical_alerts,
          monitoring_tools: monitoring_tools_status
        )
      rescue => e
        Rails.logger.error "Admin Dashboard error: #{e.message}"
        failure("Failed to load dashboard: #{e.message}")
      end
    end

    private

    def business_overview
      {
        users: {
          total: User.count,
          new_this_week: User.where(created_at: 1.week.ago..).count,
          active_subscriptions: User.joins(:subscription).where(subscriptions: { status: 'active' }).count,
          past_due: User.joins(:subscription).where(subscriptions: { status: 'past_due' }).count
        },
        revenue: {
          mrr: calculate_mrr,
          today: todays_revenue,
          this_week: this_weeks_revenue
        },
        growth: {
          user_growth_week: calculate_user_growth,
          device_growth_week: calculate_device_growth
        }
      }
    end

    def device_overview
      {
        total: Device.count,
        online: Device.where(status: 'active').count,
        offline: Device.where(last_connection: ..1.hour.ago).count,
        errors: Device.where(status: 'error').count,
        new_this_week: Device.where(created_at: 1.week.ago..).count,
        by_type: Device.joins(:device_type).group('device_types.name').count,
        connection_health: calculate_connection_health
      }
    end

    def system_overview
      {
        database: check_database_health,
        redis: check_redis_health,
        sidekiq: check_sidekiq_health,
        disk_usage: get_disk_usage_percent,
        memory_usage: get_memory_usage_mb,
        uptime: calculate_uptime
      }
    end

    def critical_alerts
      alerts = []
      
      # Device alerts
      error_devices = Device.where(status: 'error').count
      alerts << {
        type: 'error',
        message: "#{error_devices} devices in error state",
        action: 'Check device fleet',
        url: '/admin/devices?status=error'
      } if error_devices > 5

      offline_devices = Device.where(last_connection: ..1.hour.ago).count
      alerts << {
        type: 'warning', 
        message: "#{offline_devices} devices offline >1 hour",
        action: 'Check connectivity',
        url: '/admin/devices?status=offline'
      } if offline_devices > 10

      # User alerts
      past_due_users = User.joins(:subscription).where(subscriptions: { status: 'past_due' }).count
      alerts << {
        type: 'warning',
        message: "#{past_due_users} users with past due payments",
        action: 'Review billing',
        url: '/admin/users?status=past_due'
      } if past_due_users > 3

      # System alerts
      sidekiq_queue_size = Sidekiq::Queue.new.size
      alerts << {
        type: 'error',
        message: "Sidekiq queue backed up (#{sidekiq_queue_size} jobs)",
        action: 'Check background jobs',
        url: '/admin/sidekiq'
      } if sidekiq_queue_size > 100

      alerts
    end

    def monitoring_tools_status
      {
        database: {
          name: 'Database Performance',
          url: '/admin/pghero',
          status: check_database_health,
          description: 'Slow queries, connections, indexes'
        },
        background_jobs: {
          name: 'Background Jobs',
          url: '/admin/sidekiq',
          status: check_sidekiq_health,
          description: 'Job queues, failures, processing'
        },
        health_check: {
          name: 'System Health',
          url: '/health_check',
          status: 'active',
          description: 'Database, Redis, migrations'
        },
        metrics: {
          name: 'IoT Metrics',
          url: '/metrics',
          status: 'active',
          description: 'Prometheus metrics for devices'
        },
        errors: {
          name: 'Error Tracking',
          url: sentry_dashboard_url,
          status: 'external',
          description: 'Application errors and performance'
        }
      }
    end

    # === CALCULATION METHODS ===

    def calculate_mrr
      Subscription.where(status: 'active')
                 .joins(:plan)
                 .sum('plans.monthly_price')
                 .to_f
    end

    def todays_revenue
      Order.where(created_at: Date.current.all_day, status: 'completed')
           .sum(:total)
           .to_f
    end

    def this_weeks_revenue
      Order.where(created_at: 1.week.ago.., status: 'completed')
           .sum(:total)
           .to_f
    end

    def calculate_user_growth
      current_week = User.where(created_at: 1.week.ago..).count
      previous_week = User.where(created_at: 2.weeks.ago..1.week.ago).count
      return 0 if previous_week == 0
      
      ((current_week - previous_week).to_f / previous_week * 100).round(1)
    end

    def calculate_device_growth
      current_week = Device.where(created_at: 1.week.ago..).count
      previous_week = Device.where(created_at: 2.weeks.ago..1.week.ago).count
      return 0 if previous_week == 0
      
      ((current_week - previous_week).to_f / previous_week * 100).round(1)
    end

    def calculate_connection_health
      total_devices = Device.count
      return 100 if total_devices == 0
      
      online_devices = Device.where(status: 'active').count
      ((online_devices.to_f / total_devices) * 100).round(1)
    end

    # === HEALTH CHECK METHODS ===

    def check_database_health
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        connection_count = ActiveRecord::Base.connection.execute(
          "SELECT count(*) FROM pg_stat_activity"
        ).first['count']
        
        status = connection_count > 90 ? 'warning' : 'healthy'
        { status: status, connections: connection_count }
      rescue => e
        { status: 'error', error: e.message }
      end
    end

    def check_redis_health
      begin
        info = $redis.info
        memory_mb = (info['used_memory'].to_f / 1024 / 1024).round(2)
        
        status = memory_mb > 500 ? 'warning' : 'healthy'
        { status: status, memory_mb: memory_mb, connected_clients: info['connected_clients'] }
      rescue => e
        { status: 'error', error: e.message }
      end
    end

    def check_sidekiq_health
      begin
        stats = Sidekiq::Stats.new
        queue_size = stats.enqueued
        
        status = case queue_size
                when 0..50 then 'healthy'
                when 51..100 then 'warning' 
                else 'error'
                end
                
        {
          status: status,
          enqueued: queue_size,
          failed: stats.failed,
          processed: stats.processed
        }
      rescue => e
        { status: 'error', error: e.message }
      end
    end

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

    def calculate_uptime
      begin
        uptime_seconds = File.read('/proc/uptime').split.first.to_f
        uptime_days = (uptime_seconds / 86400).round(1)
        "#{uptime_days} days"
      rescue
        "Unknown"
      end
    end

    def sentry_dashboard_url
      # Return your Sentry dashboard URL or 'Not configured'
      if Rails.application.credentials.dig(Rails.env.to_sym, :sentry, :dsn).present?
        "https://sentry.io/organizations/your-org/projects/"
      else
        nil
      end
    end
  end
end