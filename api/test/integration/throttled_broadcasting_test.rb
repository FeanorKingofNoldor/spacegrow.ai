# test/integration/throttled_broadcasting_test.rb
# Run with: rails runner test/integration/throttled_broadcasting_test.rb

class ThrottledBroadcastingTest
  def self.run
    puts "🧪 Starting Throttled Broadcasting Integration Test..."
    puts "=" * 60
    
    test = new
    test.setup_test_data
    test.test_sensor_data_batching
    test.test_device_status_batching
    test.test_connection_status_batching
    test.test_manual_broadcast_service
    test.verify_batch_consolidation
    test.cleanup
    
    puts "=" * 60
    puts "✅ Throttled Broadcasting Test Complete!"
  end

  def initialize
    @test_user = nil
    @test_device = nil
    @test_sensors = []
    @start_time = Time.current
  end

  def setup_test_data
    puts "\n🏗️  Setting up test data..."
    
    # Find or create test user
    @test_user = User.find_or_create_by(email: 'throttle_test@example.com') do |user|
      user.password = 'password'
      user.role = 'user'
    end
    puts "   📧 Test user: #{@test_user.email}"

    # Find or create test device
    device_type = DeviceType.first || create_test_device_type
    @test_device = @test_user.devices.find_or_create_by(name: 'Throttle Test Device') do |device|
      device.device_type = device_type
      device.status = 'active'
    end
    puts "   📱 Test device: #{@test_device.name} (ID: #{@test_device.id})"

    # Create test sensors if they don't exist
    if @test_device.device_sensors.empty?
      ['Temperature Sensor', 'Humidity Sensor'].each do |sensor_name|
        sensor_type = SensorType.find_or_create_by(name: sensor_name) do |st|
          st.unit = sensor_name.include?('Temperature') ? '°C' : '%'
          st.min_value = 0
          st.max_value = 100
          st.normal_min = 20
          st.normal_max = 80
          st.warning_low_min = 10
          st.warning_low_max = 19
          st.warning_high_min = 81
          st.warning_high_max = 90
          st.error_low_min = 0
          st.error_low_max = 9
          st.error_high_min = 91
          st.error_high_max = 100
        end
        
        device_sensor = @test_device.device_sensors.find_or_create_by(sensor_type: sensor_type) do |ds|
          ds.current_status = 'normal'
        end
        @test_sensors << device_sensor
      end
    else
      @test_sensors = @test_device.device_sensors.to_a
    end
    puts "   🔬 Test sensors: #{@test_sensors.count} sensors created"
  end

  def test_sensor_data_batching
    puts "\n📊 Testing sensor data batching..."
    
    # Clear any existing batches
    clear_user_batches
    
    # Create multiple sensor readings rapidly
    readings_count = 5
    @test_sensors.each do |sensor|
      readings_count.times do |i|
        sensor.sensor_data.create!(
          value: 25 + i,
          timestamp: Time.current + i.seconds,
          is_valid: true,
          zone: 'normal'
        )
        sleep(0.1) # Small delay to simulate rapid readings
      end
    end
    
    puts "   📈 Created #{readings_count * @test_sensors.count} sensor readings"
    
    # Check if batches were created
    batch = get_user_batch
    if batch && batch[:sensor_data].any?
      puts "   ✅ Sensor data batching working! #{batch[:sensor_data].count} updates batched"
    else
      puts "   ❌ Sensor data batching not working - no batch found"
    end
  end

  def test_device_status_batching
    puts "\n📱 Testing device status batching..."
    
    # Clear batches
    clear_user_batches
    
    # Change sensor statuses to trigger device status updates
    @test_sensors.each_with_index do |sensor, i|
      new_status = i.even? ? 'warning' : 'error'
      sensor.update!(current_status: new_status)
      sleep(0.1)
    end
    
    # Check batches
    batch = get_user_batch
    if batch && batch[:device_status].any?
      puts "   ✅ Device status batching working! #{batch[:device_status].count} updates batched"
    else
      puts "   ❌ Device status batching not working - no batch found"
    end
  end

  def test_connection_status_batching
    puts "\n🔗 Testing connection status batching..."
    
    # Clear batches
    clear_user_batches
    
    # Update device connection multiple times
    3.times do |i|
      @test_device.update!(last_connection: Time.current + i.minutes)
      sleep(0.1)
    end
    
    # Check batches
    batch = get_user_batch
    if batch && batch[:device_status].any?
      puts "   ✅ Connection status batching working! #{batch[:device_status].count} updates batched"
    else
      puts "   ❌ Connection status batching not working - no batch found"
    end
  end

  def test_manual_broadcast_service
    puts "\n🚀 Testing manual broadcast service..."
    
    # Clear batches
    clear_user_batches
    
    # Use BroadcastService manually
    WebsocketBroadcasting::BroadcastService.new(@test_device).call
    
    # Check batches
    batch = get_user_batch
    if batch && (batch[:device_status].any? || batch[:dashboard].any?)
      puts "   ✅ Manual broadcast service working! Updates batched"
    else
      puts "   ❌ Manual broadcast service not working - no batch found"
    end
  end

  def test_batch_consolidation
    puts "\n📦 Testing batch consolidation..."
    
    # Clear batches
    clear_user_batches
    
    # Create rapid updates of different types
    5.times do |i|
      # Sensor data
      @test_sensors.first.sensor_data.create!(
        value: 30 + i,
        timestamp: Time.current + i.seconds,
        is_valid: true,
        zone: 'normal'
      )
      
      # Device status change
      @test_device.update!(last_connection: Time.current + i.seconds)
      
      sleep(0.1)
    end
    
    # Check consolidated batch
    batch = get_user_batch
    if batch
      sensor_count = batch[:sensor_data]&.count || 0
      device_count = batch[:device_status]&.count || 0
      dashboard_count = batch[:dashboard]&.count || 0
      
      total_updates = sensor_count + device_count + dashboard_count
      puts "   📊 Batch contains: #{sensor_count} sensor + #{device_count} device + #{dashboard_count} dashboard = #{total_updates} total updates"
      
      if total_updates > 0
        puts "   ✅ Batch consolidation working!"
      else
        puts "   ❌ Batch consolidation not working - empty batch"
      end
    else
      puts "   ❌ No batch found for consolidation test"
    end
  end

  def verify_batch_consolidation
    puts "\n🔍 Verifying batch will be sent..."
    
    # Wait for the batch job to be executed (or execute manually)
    batch = get_user_batch
    if batch
      puts "   ⏰ Batch found, simulating job execution..."
      
      # Manually execute the batch (simulating the background job)
      begin
        WebsocketBroadcasting::ThrottledBroadcaster.execute_user_broadcast(@test_user.id)
        puts "   ✅ Batch execution completed successfully!"
        
        # Verify batch was cleared
        after_batch = get_user_batch
        if after_batch.nil?
          puts "   ✅ Batch properly cleared after execution"
        else
          puts "   ⚠️  Batch not cleared - may indicate issue"
        end
      rescue => e
        puts "   ❌ Batch execution failed: #{e.message}"
      end
    else
      puts "   ℹ️  No batch to execute"
    end
  end

  def cleanup
    puts "\n🧹 Cleaning up test data..."
    
    # Clean up test data
    @test_device&.sensor_data&.where('created_at > ?', @start_time)&.delete_all
    clear_user_batches
    
    puts "   ✅ Cleanup complete"
  end

  private

  def create_test_device_type
    DeviceType.create!(
      name: 'Test Device Type',
      description: 'Device type for testing',
      configuration: {
        'supported_sensor_types' => {
          'Temperature Sensor' => { 'required' => true, 'payload_key' => 'temp', 'unit' => '°C' },
          'Humidity Sensor' => { 'required' => true, 'payload_key' => 'hum', 'unit' => '%' }
        }
      }
    )
  end

  def get_user_batch
    cache_key = "throttled_broadcast_batch_#{@test_user.id}"
    Rails.cache.read(cache_key)
  end

  def clear_user_batches
    batch_key = "throttled_broadcast_batch_#{@test_user.id}"
    schedule_key = "throttled_broadcast_scheduled_#{@test_user.id}"
    Rails.cache.delete(batch_key)
    Rails.cache.delete(schedule_key)
  end
end

# Run the test if this file is executed directly
if __FILE__ == $0 || ARGV.include?('--run-test')
  ThrottledBroadcastingTest.run
end