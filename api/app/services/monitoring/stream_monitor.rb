# app/services/monitoring/stream_monitor.rb
module Monitoring
  class StreamMonitor < ApplicationService
    def self.check_consolidation_status
      new.check_consolidation_status
    end

    def check_consolidation_status
      puts "📊 WebSocket Stream Consolidation Status"
      puts "=" * 50

      # Check ActionCable server connections
      total_connections = ActionCable.server.connections.count
      puts "🔗 Total WebSocket connections: #{total_connections}"

      if total_connections > 0
        check_connection_streams
      else
        puts "ℹ️  No active WebSocket connections to analyze"
      end

      check_redis_streams
      calculate_memory_savings
      puts "=" * 50
    end

    private

    def check_connection_streams
      puts "\n📡 Stream Analysis:"
      
      ActionCable.server.connections.each_with_index do |connection, index|
        next unless connection.respond_to?(:current_user) && connection.current_user

        user = connection.current_user
        puts "\n👤 User #{user.id} (#{user.email}):"
        puts "   📱 Devices: #{user.devices.count}"
        puts "   🔬 Sensors: #{user.devices.joins(:device_sensors).count}"
        
        # Calculate old vs new stream counts
        old_stream_count = calculate_old_stream_count(user)
        new_stream_count = 5 # Always 5 with consolidation
        
        puts "   📊 Old stream count: #{old_stream_count}"
        puts "   📊 New stream count: #{new_stream_count}" 
        puts "   💾 Memory reduction: #{((old_stream_count - new_stream_count).to_f / old_stream_count * 100).round(1)}%"
        
        break if index >= 2 # Only show first 3 users for brevity
      end
    end

    def check_redis_streams
      puts "\n🗄️  Redis Stream Analysis:"
      
      # Count Redis keys for different stream types
      redis_keys = $redis.keys("*")
      
      # Old style stream keys (should be fewer after consolidation)
      old_device_keys = redis_keys.select { |k| k.match?(/device_sensor_\d+/) }.count
      old_status_keys = redis_keys.select { |k| k.match?(/device_status_\d+/) }.count
      old_chart_keys = redis_keys.select { |k| k.match?(/device_details_charts_\d+/) }.count
      
      # New style consolidated keys 
      new_user_keys = redis_keys.select { |k| k.match?(/user_(devices|sensors|dashboard|alerts)_\d+/) }.count
      
      # Throttling keys
      throttle_keys = redis_keys.select { |k| k.match?(/throttled_broadcast/) }.count
      
      puts "   🔴 Old individual streams: #{old_device_keys + old_status_keys + old_chart_keys}"
      puts "   🟢 New consolidated streams: #{new_user_keys}"
      puts "   ⚡ Throttling cache keys: #{throttle_keys}"
      
      total_actioncable_keys = redis_keys.select { |k| k.start_with?('actioncable:') }.count
      puts "   📡 Total ActionCable keys: #{total_actioncable_keys}"
    end

    def calculate_memory_savings
      puts "\n💾 Estimated Memory Savings:"
      
      # Get sample user
      sample_user = User.joins(:devices).first
      return puts "   ℹ️  No users with devices found" unless sample_user
      
      old_streams = calculate_old_stream_count(sample_user)
      new_streams = 5
      reduction_percentage = ((old_streams - new_streams).to_f / old_streams * 100).round(1)
      
      puts "   📊 Sample user analysis:"
      puts "     • Old streams per user: #{old_streams}"
      puts "     • New streams per user: #{new_streams}"
      puts "     • Reduction per user: #{reduction_percentage}%"
      
      # Estimate for scale
      total_users = User.count
      puts "   📈 Scaling estimates:"
      puts "     • Total users: #{total_users}"
      puts "     • Old total streams: #{total_users * old_streams}"
      puts "     • New total streams: #{total_users * new_streams}"
      puts "     • Total streams saved: #{total_users * (old_streams - new_streams)}"
      
      # Memory estimates (rough calculation)
      memory_per_stream = 50 # KB per stream (rough estimate)
      memory_saved_kb = total_users * (old_streams - new_streams) * memory_per_stream
      memory_saved_mb = (memory_saved_kb / 1024.0).round(1)
      
      puts "   💾 Estimated memory savings: #{memory_saved_mb} MB"
    end

    def calculate_old_stream_count(user)
      # Calculate what the old stream count would have been
      device_count = user.devices.count
      sensor_count = user.devices.joins(:device_sensors).count
      
      streams = 1 # main user stream
      streams += device_count # stream_for device
      streams += device_count * 4 # device_details_status, device_details_charts, device_status, device_sensors  
      streams += sensor_count # device_sensor streams
      
      streams
    end
  end
end

# Console helper for easy access
class StreamMonitor
  def self.check
    Monitoring::StreamMonitor.check_consolidation_status
  end
end