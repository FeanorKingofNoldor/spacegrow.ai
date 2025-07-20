# app/services/admin/operational_metrics_service.rb
module Admin
  class OperationalMetricsService < ApplicationService
    def initialize(period = 'month')
      @period = period
      @date_range = calculate_date_range(period)
    end

    def call
      begin
        operational_metrics = {
          device_operations: calculate_device_operational_metrics,
          user_operations: calculate_user_operational_metrics,
          system_health: calculate_basic_system_health,
          data_operations: calculate_data_operations_metrics
        }

        success(
          operational_metrics: operational_metrics,
          period: @period,
          date_range: {
            start: @date_range.begin.iso8601,
            end: @date_range.end.iso8601
          },
          operational_summary: generate_operational_summary(operational_metrics),
          health_score: calculate_overall_health_score(operational_metrics),
          last_updated: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Operational metrics error: #{e.message}"
        failure("Failed to calculate operational metrics: #{e.message}")
      end
    end

    private

    attr_reader :period, :date_range

    def calculate_device_operational_metrics
      # Use existing Device model admin methods - REAL DATA
      device_overview = Device.admin_fleet_overview
      health_trends = Device.admin_health_trends(7)
      performance_summary = Device.admin_performance_summary
      maintenance_queue = Device.admin_maintenance_queue
      
      {
        # Real fleet data from Device model
        fleet_overview: device_overview,
        device_health_trends: health_trends,
        fleet_performance: performance_summary,
        maintenance_queue: maintenance_queue,
        
        # Real device metrics calculated from actual data
        total_devices: Device.count,
        active_devices: Device.active.count,
        offline_devices: Device.offline.count,
        error_devices: Device.with_errors.count,
        recently_registered: Device.where(created_at: @date_range).count,
        
        # Real connectivity metrics
        connectivity_rate: calculate_device_connectivity_rate,
        avg_uptime: calculate_average_device_uptime
      }
    end

    def calculate_user_operational_metrics
      # Real user metrics from actual database queries
      {
        total_users: User.count,
        active_users_period: User.where(last_sign_in_at: @date_range).count,
        new_users_period: User.where(created_at: @date_range).count,
        users_with_devices: User.joins(:devices).distinct.count,
        users_with_subscriptions: User.joins(:subscription).where(subscriptions: { status: 'active' }).count,
        
        # Real engagement metrics
        daily_active_users: calculate_daily_active_users,
        user_retention_rate: calculate_user_retention_rate,
        avg_devices_per_user: calculate_avg_devices_per_user
      }
    end

    def calculate_basic_system_health
      # Real system metrics we can actually calculate
      {
        database_health: assess_database_health,
        active_job_health: assess_active_job_health,
        redis_health: assess_redis_health,
        storage_usage: assess_storage_usage
      }
    end

    def calculate_data_operations_metrics
      # Real sensor data metrics
      {
        total_sensor_readings: SensorData.where(created_at: @date_range).count,
        avg_readings_per_day: calculate_avg_readings_per_day,
        data_growth_rate: calculate_data_growth_rate,
        top_sensor_types: calculate_top_sensor_types,
        device_data_distribution: calculate_device_data_distribution
      }
    end

    # ===== REAL CALCULATION METHODS =====

    def calculate_device_connectivity_rate
      total_devices = Device.count
      return 0 if total_devices == 0
      
      active_devices = Device.active.count
      ((active_devices.to_f / total_devices) * 100).round(2)
    end

    def calculate_average_device_uptime
      # Calculate based on device last_seen timestamps
      active_devices = Device.active.includes(:sensor_data)
      return 0 if active_devices.empty?
      
      uptimes = active_devices.map do |device|
        last_seen = device.sensor_data.maximum(:created_at)
        next 0 unless last_seen
        
        # Calculate uptime percentage based on expected check-ins
        expected_checkins = (@date_range.end - @date_range.begin) / 1.hour
        actual_hours = device.sensor_data.where(created_at: @date_range).group_by_hour(:created_at).count.size
        
        next 0 if expected_checkins == 0
        ((actual_hours.to_f / expected_checkins) * 100).round(2)
      end
      
      uptimes.compact.sum / uptimes.compact.size
    end

    def calculate_daily_active_users
      # Users who have logged in or have device activity in the period
      User.where(last_sign_in_at: @date_range)
          .or(User.joins(devices: :sensor_data).where(sensor_data: { created_at: @date_range }))
          .distinct
          .count
    end

    def calculate_user_retention_rate
      # Calculate retention rate for users created in previous period
      previous_period = calculate_previous_period(@date_range)
      new_users_previous = User.where(created_at: previous_period)
      active_in_current = new_users_previous.where(last_sign_in_at: @date_range)
      
      return 0 if new_users_previous.count == 0
      ((active_in_current.count.to_f / new_users_previous.count) * 100).round(2)
    end

    def calculate_avg_devices_per_user
      total_users = User.count
      return 0 if total_users == 0
      
      (Device.count.to_f / total_users).round(2)
    end

    def calculate_avg_readings_per_day
      total_readings = SensorData.where(created_at: @date_range).count
      days_in_period = (@date_range.end.to_date - @date_range.begin.to_date).to_i + 1
      
      return 0 if days_in_period == 0
      (total_readings.to_f / days_in_period).round(0)
    end

    def calculate_data_growth_rate
      current_period_data = SensorData.where(created_at: @date_range).count
      previous_period = calculate_previous_period(@date_range)
      previous_period_data = SensorData.where(created_at: previous_period).count
      
      return 0 if previous_period_data == 0
      (((current_period_data - previous_period_data).to_f / previous_period_data) * 100).round(2)
    end

    def calculate_top_sensor_types
      SensorData.joins(:device_sensor)
               .joins(device_sensor: :sensor_type)
               .where(created_at: @date_range)
               .group('sensor_types.name')
               .count
               .sort_by { |_, count| -count }
               .first(5)
               .to_h
    end

    def calculate_device_data_distribution
      Device.joins(:sensor_data)
            .where(sensor_data: { created_at: @date_range })
            .group('devices.id')
            .count
            .values
            .then do |readings_per_device|
              return {} if readings_per_device.empty?
              
              {
                min_readings: readings_per_device.min,
                max_readings: readings_per_device.max,
                avg_readings: (readings_per_device.sum.to_f / readings_per_device.size).round(2),
                median_readings: readings_per_device.sort[readings_per_device.size / 2]
              }
            end
    end

    # ===== HEALTH ASSESSMENT METHODS =====

    def assess_database_health
      begin
        # Test database responsiveness
        start_time = Time.current
        ActiveRecord::Base.connection.execute("SELECT 1")
        response_time = ((Time.current - start_time) * 1000).round(2)
        
        {
          status: response_time < 100 ? 'healthy' : 'slow',
          response_time_ms: response_time,
          connection_pool_size: ActiveRecord::Base.connection_pool.size,
          active_connections: ActiveRecord::Base.connection_pool.connections.size
        }
      rescue => e
        {
          status: 'error',
          error: e.message
        }
      end
    end

    def assess_active_job_health
      begin
        # Check for failed jobs and queue sizes
        failed_jobs = ActiveJob::Base.queue_adapter.respond_to?(:failed) ? 
                     ActiveJob::Base.queue_adapter.failed.size : 0
        
        {
          status: failed_jobs < 10 ? 'healthy' : 'attention_needed',
          failed_jobs_count: failed_jobs
        }
      rescue => e
        {
          status: 'unknown',
          error: e.message
        }
      end
    end

    def assess_redis_health
      begin
        # Test Redis connectivity if available
        if defined?(Redis) && Rails.cache.respond_to?(:redis)
          start_time = Time.current
          Rails.cache.redis.ping
          response_time = ((Time.current - start_time) * 1000).round(2)
          
          {
            status: response_time < 50 ? 'healthy' : 'slow',
            response_time_ms: response_time
          }
        else
          { status: 'not_configured' }
        end
      rescue => e
        {
          status: 'error',
          error: e.message
        }
      end
    end

    def assess_storage_usage
      begin
        # Get basic storage info
        {
          total_sensor_data_records: SensorData.count,
          total_devices: Device.count,
          total_users: User.count,
          database_size_estimate: estimate_database_size
        }
      rescue => e
        {
          status: 'error',
          error: e.message
        }
      end
    end

    def estimate_database_size
      # Rough estimate based on record counts
      sensor_data_size = SensorData.count * 0.1 # Assume ~100 bytes per reading
      device_size = Device.count * 0.5 # Assume ~500 bytes per device
      user_size = User.count * 1 # Assume ~1KB per user
      
      "#{(sensor_data_size + device_size + user_size).round(2)} KB (estimated)"
    end

    # ===== SUMMARY AND SCORING METHODS =====

    def generate_operational_summary(metrics)
      {
        device_health: assess_device_health(metrics[:device_operations]),
        user_activity: assess_user_activity(metrics[:user_operations]),
        system_status: assess_system_status(metrics[:system_health]),
        data_processing: assess_data_processing(metrics[:data_operations])
      }
    end

    def calculate_overall_health_score(metrics)
      device_score = calculate_device_health_score(metrics[:device_operations])
      user_score = calculate_user_activity_score(metrics[:user_operations])
      system_score = calculate_system_health_score(metrics[:system_health])
      data_score = calculate_data_health_score(metrics[:data_operations])
      
      # Weighted average
      ((device_score * 0.4) + (user_score * 0.3) + (system_score * 0.2) + (data_score * 0.1)).round(1)
    end

    def assess_device_health(device_metrics)
      connectivity_rate = device_metrics[:connectivity_rate]
      
      case connectivity_rate
      when 90..100 then 'excellent'
      when 75..89 then 'good'
      when 60..74 then 'fair'
      else 'poor'
      end
    end

    def assess_user_activity(user_metrics)
      retention_rate = user_metrics[:user_retention_rate]
      
      case retention_rate
      when 80..100 then 'excellent'
      when 60..79 then 'good'
      when 40..59 then 'fair'
      else 'poor'
      end
    end

    def assess_system_status(system_metrics)
      db_healthy = system_metrics[:database_health][:status] == 'healthy'
      redis_healthy = system_metrics[:redis_health][:status] == 'healthy'
      
      if db_healthy && redis_healthy
        'excellent'
      elsif db_healthy
        'good'
      else
        'poor'
      end
    end

    def assess_data_processing(data_metrics)
      growth_rate = data_metrics[:data_growth_rate]
      
      case growth_rate
      when 0..20 then 'stable'
      when 21..50 then 'growing'
      when 51..100 then 'rapid_growth'
      else 'exponential_growth'
      end
    end

    def calculate_device_health_score(device_metrics)
      connectivity_rate = device_metrics[:connectivity_rate] || 0
      uptime = device_metrics[:avg_uptime] || 0
      
      # Weighted score
      ((connectivity_rate * 0.6) + (uptime * 0.4)).round(1)
    end

    def calculate_user_activity_score(user_metrics)
      retention_rate = user_metrics[:user_retention_rate] || 0
      activity_ratio = user_metrics[:active_users_period].to_f / [user_metrics[:total_users], 1].max * 100
      
      # Weighted score
      ((retention_rate * 0.7) + (activity_ratio * 0.3)).round(1)
    end

    def calculate_system_health_score(system_metrics)
      scores = []
      
      # Database health score
      if system_metrics[:database_health][:status] == 'healthy'
        scores << 100
      elsif system_metrics[:database_health][:status] == 'slow'
        scores << 70
      else
        scores << 30
      end
      
      # Redis health score
      if system_metrics[:redis_health][:status] == 'healthy'
        scores << 100
      elsif system_metrics[:redis_health][:status] == 'slow'
        scores << 70
      else
        scores << 50
      end
      
      scores.sum / scores.size
    end

    def calculate_data_health_score(data_metrics)
      # Score based on data consistency and growth
      readings_today = data_metrics[:avg_readings_per_day]
      
      if readings_today > 1000
        90
      elsif readings_today > 100
        75
      elsif readings_today > 10
        60
      else
        40
      end
    end

    # ===== UTILITY METHODS =====

    def calculate_date_range(period)
      case period
      when 'today'
        Date.current.all_day
      when 'week'
        1.week.ago..Time.current
      when 'month'
        1.month.ago..Time.current
      when 'quarter'
        3.months.ago..Time.current
      when 'year'
        1.year.ago..Time.current
      else
        1.month.ago..Time.current
      end
    end

    def calculate_previous_period(date_range)
      duration = date_range.end - date_range.begin
      (date_range.begin - duration)..(date_range.begin)
    end
  end
end