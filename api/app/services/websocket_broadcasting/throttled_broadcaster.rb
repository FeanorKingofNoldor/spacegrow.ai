# app/services/real_time/throttled_broadcaster.rb
module WebsocketBroadcasting
  class ThrottledBroadcaster < ApplicationService
    THROTTLE_INTERVAL = 5.seconds
    CACHE_PREFIX = 'throttled_broadcast'
    
    class << self
      # Main entry point for sensor data broadcasting
      def broadcast_sensor_data(device_sensor_id, data_point)
        device_sensor = DeviceSensor.find(device_sensor_id)
        device = device_sensor.device
        user = device.user
        
        # Check if user has active WebSocket connection
        return unless user_has_active_session?(user)
        
        # Add to user's pending sensor updates
        add_to_user_batch(user.id, :sensor_data, {
          device_id: device.id,
          sensor_id: device_sensor_id,
          sensor_type: device_sensor.sensor_type.name,
          data_point: data_point,
          timestamp: Time.current.iso8601
        })
        
        # Schedule batch broadcast if not already scheduled
        schedule_user_broadcast(user.id)
        
        Rails.logger.debug "📊 [ThrottledBroadcaster] Added sensor data for user #{user.id}, device #{device.id}"
      end
      
      # Entry point for device status broadcasting
      def broadcast_device_status(device_id, status_data)
        device = Device.find(device_id)
        user = device.user
        
        return unless user_has_active_session?(user)
        
        # Use existing DeviceManagement::StatusService for efficient status calculation
        device_status = Devices::DeviceManagement::StatusService.new(device).call
        
        add_to_user_batch(user.id, :device_status, {
          device_id: device.id,
          device_status: device_status,
          status_data: status_data,
          timestamp: Time.current.iso8601
        })
        
        schedule_user_broadcast(user.id)
        
        Rails.logger.debug "📱 [ThrottledBroadcaster] Added device status for user #{user.id}, device #{device.id}"
      end
      
      # Entry point for dashboard updates
      def broadcast_dashboard_update(user_id)
        user = User.find(user_id)
        
        return unless user_has_active_session?(user)
        
        # Use existing DeviceManagement::AggregationService for efficient dashboard stats
        dashboard_stats = Devices::DeviceManagement::AggregationService.new(user.devices).call
        
        add_to_user_batch(user.id, :dashboard, {
          user_id: user.id,
          stats: dashboard_stats,
          device_count: user.devices.count,
          timestamp: Time.current.iso8601
        })
        
        schedule_user_broadcast(user.id)
        
        Rails.logger.debug "📈 [ThrottledBroadcaster] Added dashboard update for user #{user.id}"
      end
      
      private
      
      # Check if user has active WebSocket connection
      def user_has_active_session?(user)
        # Check ActionCable server for active connections
        active_connections = ActionCable.server.connections.select do |connection|
          connection.current_user&.id == user.id
        rescue
          false
        end
        
        has_connection = active_connections.any?
        
        unless has_connection
          Rails.logger.debug "🚫 [ThrottledBroadcaster] User #{user.id} has no active session, skipping broadcast"
        end
        
        has_connection
      end
      
      # Add update to user's pending batch
      def add_to_user_batch(user_id, update_type, data)
        cache_key = user_batch_key(user_id)
        
        # Get existing batch or create new one
        user_batch = Rails.cache.read(cache_key) || {
          sensor_data: [],
          device_status: [],
          dashboard: [],
          created_at: Time.current.iso8601
        }
        
        # Add new data to appropriate category
        user_batch[update_type] << data
        
        # Store back to cache with expiration
        Rails.cache.write(cache_key, user_batch, expires_in: THROTTLE_INTERVAL + 1.second)
        
        Rails.logger.debug "📦 [ThrottledBroadcaster] Batch for user #{user_id} now has #{user_batch[update_type].length} #{update_type} updates"
      end
      
      # Schedule broadcast for user if not already scheduled
      def schedule_user_broadcast(user_id)
        schedule_key = user_schedule_key(user_id)
        
        # Check if broadcast already scheduled for this user
        unless Rails.cache.read(schedule_key)
          # Mark as scheduled
          Rails.cache.write(schedule_key, true, expires_in: THROTTLE_INTERVAL)
          
          # Schedule the actual broadcast
          BroadcastUserBatchJob.set(wait: THROTTLE_INTERVAL).perform_later(user_id)
          
          Rails.logger.debug "⏰ [ThrottledBroadcaster] Scheduled batch broadcast for user #{user_id} in #{THROTTLE_INTERVAL} seconds"
        end
      end
      
      # Execute the batched broadcast for a user
      def execute_user_broadcast(user_id)
        cache_key = user_batch_key(user_id)
        schedule_key = user_schedule_key(user_id)
        
        # Get and clear the batch
        user_batch = Rails.cache.read(cache_key)
        Rails.cache.delete(cache_key)
        Rails.cache.delete(schedule_key)
        
        return unless user_batch
        
        # Double-check user still has active session
        user = User.find_by(id: user_id)
        return unless user && user_has_active_session?(user)
        
        # Prepare consolidated payload
        payload = build_consolidated_payload(user_batch)
        
        # Broadcast to user's streams
        broadcast_to_user_streams(user, payload)
        
        # Log performance metrics
        log_broadcast_metrics(user_id, user_batch, payload)
      end
      
      # Build consolidated payload from batched updates
      def build_consolidated_payload(user_batch)
        payload = {
          type: 'batch_update',
          timestamp: Time.current.iso8601,
          updates: {}
        }
        
        # Add sensor data updates if any
        if user_batch[:sensor_data].any?
          payload[:updates][:sensor_data] = consolidate_sensor_data(user_batch[:sensor_data])
        end
        
        # Add device status updates if any
        if user_batch[:device_status].any?
          payload[:updates][:device_status] = consolidate_device_status(user_batch[:device_status])
        end
        
        # Add dashboard updates if any
        if user_batch[:dashboard].any?
          payload[:updates][:dashboard] = user_batch[:dashboard].last # Only need latest dashboard stats
        end
        
        payload
      end
      
      # Consolidate multiple sensor data points
      def consolidate_sensor_data(sensor_updates)
        # Group by device_id for efficient frontend processing
        grouped_by_device = sensor_updates.group_by { |update| update[:device_id] }
        
        grouped_by_device.transform_values do |device_updates|
          # Group by sensor for this device
          grouped_by_sensor = device_updates.group_by { |update| update[:sensor_id] }
          
          grouped_by_sensor.transform_values do |sensor_updates|
            {
              sensor_type: sensor_updates.first[:sensor_type],
              data_points: sensor_updates.map { |update| update[:data_point] },
              latest_timestamp: sensor_updates.last[:timestamp]
            }
          end
        end
      end
      
      # Consolidate device status updates
      def consolidate_device_status(status_updates)
        # Group by device_id and take latest status for each device
        grouped_by_device = status_updates.group_by { |update| update[:device_id] }
        
        grouped_by_device.transform_values do |device_updates|
          latest_update = device_updates.last
          {
            device_status: latest_update[:device_status],
            status_data: latest_update[:status_data],
            timestamp: latest_update[:timestamp]
          }
        end
      end
      
      # Broadcast consolidated payload to user's streams
      def broadcast_to_user_streams(user, payload)
        # Main consolidated broadcast to user stream (contains everything)
        DeviceChannel.broadcast_to(user, payload)
        
        # ✅ NEW: Also broadcast to specific consolidated streams for targeted updates
        if payload[:updates][:sensor_data].present?
          DeviceChannel.broadcast_to_user_sensors(user.id, payload[:updates][:sensor_data])
        end
        
        if payload[:updates][:device_status].present?
          DeviceChannel.broadcast_to_user_devices(user.id, payload[:updates][:device_status])
        end
        
        if payload[:updates][:dashboard].present?
          DeviceChannel.broadcast_to_user_dashboard(user.id, payload[:updates][:dashboard])
        end
        
        Rails.logger.info "📡 [ThrottledBroadcaster] Consolidated broadcast sent to user #{user.id} across #{count_active_streams(payload)} streams"
      end
      
      # Log performance metrics
      def log_broadcast_metrics(user_id, user_batch, payload)
        sensor_count = user_batch[:sensor_data]&.length || 0
        device_count = user_batch[:device_status]&.length || 0
        dashboard_count = user_batch[:dashboard]&.length || 0
        
        Rails.logger.info "📊 [ThrottledBroadcaster] Metrics for user #{user_id}: " \
                         "#{sensor_count} sensor updates, " \
                         "#{device_count} device updates, " \
                         "#{dashboard_count} dashboard updates " \
                         "consolidated into 1 broadcast"
        
        # Track metrics in cache for monitoring
        increment_broadcast_metric('batched_broadcasts_sent')
        increment_broadcast_metric('sensor_updates_batched', sensor_count)
        increment_broadcast_metric('device_updates_batched', device_count)
      end
      
      # Increment broadcast metrics
      def increment_broadcast_metric(metric_name, count = 1)
        metric_key = "#{CACHE_PREFIX}_metrics_#{metric_name}_#{Date.current}"
        Rails.cache.increment(metric_key, count, expires_in: 1.day)
      end
      
      # Cache key helpers
      def user_batch_key(user_id)
        "#{CACHE_PREFIX}_batch_#{user_id}"
      end
      
      def user_schedule_key(user_id)
        "#{CACHE_PREFIX}_scheduled_#{user_id}"
      end
    end
  end

  def count_active_streams(payload)
    stream_count = 1 # Main user stream always active
    stream_count += 1 if payload[:updates][:sensor_data].present?
    stream_count += 1 if payload[:updates][:device_status].present?  
    stream_count += 1 if payload[:updates][:dashboard].present?
    stream_count
  end
end