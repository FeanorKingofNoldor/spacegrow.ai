# app/services/admin/system_service.rb - SIMPLIFIED FOR STARTUP
module Admin
  class SystemService < ApplicationService
    def health_check
      begin
        success(
          database: check_database_health,
          redis: check_redis_health,
          sidekiq: check_sidekiq_health,
          timestamp: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Admin Health Check error: #{e.message}"
        failure("Failed to perform health check: #{e.message}")
      end
    end

    private

    def check_database_health
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        connections = ActiveRecord::Base.connection.execute(
          "SELECT count(*) as count FROM pg_stat_activity"
        ).first['count']
        
        {
          status: connections > 90 ? 'warning' : 'healthy',
          connections: connections,
          message: connections > 90 ? 'High connection count' : 'Database OK'
        }
      rescue => e
        {
          status: 'error',
          message: "Database error: #{e.message}"
        }
      end
    end

    def check_redis_health
      begin
        if defined?($redis) && $redis
          $redis.ping
          info = $redis.info
          memory_mb = (info['used_memory'].to_f / 1024 / 1024).round(2)
          
          {
            status: memory_mb > 500 ? 'warning' : 'healthy',
            memory_mb: memory_mb,
            message: memory_mb > 500 ? 'High memory usage' : 'Redis OK'
          }
        else
          { status: 'not_configured', message: 'Redis not configured' }
        end
      rescue => e
        {
          status: 'error',
          message: "Redis error: #{e.message}"
        }
      end
    end

    def check_sidekiq_health
      begin
        require 'sidekiq/api'
        queue_size = Sidekiq::Queue.new.size
        
        {
          status: queue_size > 100 ? 'warning' : 'healthy',
          queue_size: queue_size,
          message: queue_size > 100 ? 'Queue backed up' : 'Sidekiq OK'
        }
      rescue => e
        {
          status: 'error',
          message: "Sidekiq error: #{e.message}"
        }
      end
    end
  end
end