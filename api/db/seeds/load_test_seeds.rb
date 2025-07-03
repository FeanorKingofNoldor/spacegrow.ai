# db/seeds/load_test_seeds.rb - Load Testing Seed Data
# Run with: rails db:seed:load_test_seeds

return unless Rails.env.development? || Rails.env.test?

puts "🌱 Creating load testing seed data..."

# Create a test user for load testing
test_user = User.find_or_create_by(email: 'test@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = 'user'
  user.timezone = 'UTC'
end

puts "✅ Test user created: #{test_user.email}"

# Create device types if they don't exist (based on your working mock_data)
environmental_monitor = DeviceType.find_or_create_by(name: 'Environmental Monitor V1') do |dt|
  dt.description = 'Environmental monitoring device for load testing'
  # Add configuration similar to your working devices
  dt.configuration = {
    'supported_sensor_types' => {
      'temperature' => { 'payload_key' => 'temp' },
      'humidity' => { 'payload_key' => 'hum' }
    }
  }
end

liquid_monitor = DeviceType.find_or_create_by(name: 'Liquid Monitor V1') do |dt|
  dt.description = 'Liquid monitoring device for load testing'
  dt.configuration = {
    'supported_sensor_types' => {
      'ph' => { 'payload_key' => 'ph' },
      'temperature' => { 'payload_key' => 'temp' }
    }
  }
end

puts "✅ Device types created"

# Create some sensor types for testing (using the correct attributes)
sensor_types = [
  {
    name: 'temperature',
    unit: '°C',
    min_value: -10.0,
    max_value: 50.0,
    error_low_min: -10.0,
    error_low_max: 0.0,
    warning_low_min: 0.0,
    warning_low_max: 10.0,
    normal_min: 10.0,
    normal_max: 30.0,
    warning_high_min: 30.0,
    warning_high_max: 40.0,
    error_high_min: 40.0,
    error_high_max: 50.0
  },
  {
    name: 'humidity',
    unit: '%',
    min_value: 0.0,
    max_value: 100.0,
    error_low_min: 0.0,
    error_low_max: 20.0,
    warning_low_min: 20.0,
    warning_low_max: 40.0,
    normal_min: 40.0,
    normal_max: 80.0,
    warning_high_min: 80.0,
    warning_high_max: 90.0,
    error_high_min: 90.0,
    error_high_max: 100.0
  },
  {
    name: 'ph',
    unit: 'pH',
    min_value: 0.0,
    max_value: 14.0,
    error_low_min: 0.0,
    error_low_max: 4.0,
    warning_low_min: 4.0,
    warning_low_max: 6.0,
    normal_min: 6.0,
    normal_max: 8.0,
    warning_high_min: 8.0,
    warning_high_max: 10.0,
    error_high_min: 10.0,
    error_high_max: 14.0
  }
]

sensor_types.each do |st_attrs|
  SensorType.find_or_create_by(name: st_attrs[:name]) do |st|
    st.assign_attributes(st_attrs)
  end
end

puts "✅ Sensor types created"

# Create test products for device activation (following your working pattern)
environmental_product = Product.find_or_create_by(device_type: environmental_monitor) do |p|
  p.name = 'Test Environmental Monitor'
  p.price = 199.99
  p.active = true
  p.category = 'devices'
  p.description = 'Test environmental monitoring device'
  p.features = ['Temperature monitoring', 'Humidity control']
end

liquid_product = Product.find_or_create_by(device_type: liquid_monitor) do |p|
  p.name = 'Test Liquid Monitor'
  p.price = 149.99
  p.active = true
  p.category = 'devices'
  p.description = 'Test liquid monitoring device'
  p.features = ['pH monitoring', 'Temperature control']
end

puts "✅ Test products created"

# Create subscription for test user (following your working pattern)
plan = Plan.find_or_create_by(name: 'Professional') do |p|
  p.price = 29.99
  p.interval = 'month'
  p.max_devices = 10
  p.features = ['Multiple devices', 'Advanced analytics']
end

subscription = Subscription.find_or_create_by(user: test_user) do |s|
  s.plan = plan
  s.status = 'active'
  s.current_period_start = Time.current
  s.current_period_end = 1.month.from_now
end

puts "✅ Test subscription created"

# Create test devices using the same pattern as your working mock_data
test_devices_data = [
  { product: environmental_product, name: 'Test Environmental Monitor' },
  { product: liquid_product, name: 'Test Liquid Monitor' }
]

test_devices_data.each do |device_data|
  # Create order and activate device (following your working pattern)
  order = Order.find_or_create_by(
    user: test_user, 
    status: 'paid',
    total: device_data[:product].price
  )
  
  LineItem.find_or_create_by(order: order, product: device_data[:product]) do |li|
    li.quantity = 1
    li.price = device_data[:product].price
  end
  
  # Create activation token
  activation_token = DeviceActivationToken.find_or_create_by(
    device_type: device_data[:product].device_type,
    order: order
  ) do |token|
    token.token = SecureRandom.hex(16)
    token.expires_at = 30.days.from_now
  end
  
  # Activate device using the service (if it exists)
  begin
    if defined?(DeviceActivationService)
      result = DeviceActivationService.call(
        token: activation_token.token,
        device_type: device_data[:product].device_type
      )
      device = result.device
    else
      # Manual device creation if service doesn't exist
      device = Device.find_or_create_by(
        name: device_data[:name],
        device_type: device_data[:product].device_type,
        user: test_user
      ) do |d|
        d.status = 'active'
        d.alert_status = 'normal'
        d.last_connection = Time.current
        d.activation_token = activation_token
      end
    end
    
    # Update device status
    device.update!(
      status: 'active',
      last_connection: Time.current
    )
    
    # Add to subscription
    SubscriptionDevice.find_or_create_by(
      subscription: subscription,
      device: device
    ) do |sd|
      sd.monthly_cost = 10.00
    end
    
    puts "✅ Test device created: #{device.name} (ID: #{device.id})"
    
  rescue => e
    puts "⚠️  Error creating device #{device_data[:name]}: #{e.message}"
    puts "   Creating basic device instead..."
    
    # Fallback: create basic device
    device = test_user.devices.find_or_create_by(name: device_data[:name]) do |d|
      d.device_type = device_data[:product].device_type
      d.status = 'active'
      d.alert_status = 'normal'
      d.last_connection = Time.current
    end
    
    puts "✅ Basic test device created: #{device.name}"
  end
end

# Create some predefined presets for testing (if Preset model exists)
if defined?(Preset)
  # Environmental Monitor Presets
  env_presets = [
    {
      name: 'Cannabis',
      device_type_id: environmental_monitor.id,
      is_user_defined: false,
      settings: {
        lights: {
          on_at: '08:00hrs',
          off_at: '20:00hrs'
        },
        spray: {
          on_for: 10,
          off_for: 30
        }
      }
    },
    {
      name: 'Chili',
      device_type_id: environmental_monitor.id,
      is_user_defined: false,
      settings: {
        lights: {
          on_at: '06:00hrs',
          off_at: '22:00hrs'
        },
        spray: {
          on_for: 15,
          off_for: 45
        }
      }
    }
  ]
  
  # Liquid Monitor Presets
  liquid_presets = [
    {
      name: 'Preset 1',
      device_type_id: liquid_monitor.id,
      is_user_defined: false,
      settings: {
        pump1: { duration: 10 },
        pump2: { duration: 0 },
        pump3: { duration: 5 },
        pump4: { duration: 0 },
        pump5: { duration: 8 }
      }
    },
    {
      name: 'Preset 2',
      device_type_id: liquid_monitor.id,
      is_user_defined: false,
      settings: {
        pump1: { duration: 0 },
        pump2: { duration: 12 },
        pump3: { duration: 0 },
        pump4: { duration: 7 },
        pump5: { duration: 0 }
      }
    }
  ]
  
  (env_presets + liquid_presets).each do |preset_attrs|
    Preset.find_or_create_by(
      name: preset_attrs[:name],
      device_type_id: preset_attrs[:device_type_id],
      is_user_defined: preset_attrs[:is_user_defined]
    ) do |preset|
      preset.settings = preset_attrs[:settings]
    end
  end
  
  puts "✅ Predefined presets created"
else
  puts "ℹ️  Preset model not found, skipping preset creation"
end

# Clean up old load test data (devices created during testing)
begin
  old_test_devices = Device.where("name LIKE 'Load Test Device%' AND created_at < ?", 1.hour.ago)
  deleted_count = old_test_devices.count
  old_test_devices.destroy_all
  
  if deleted_count > 0
    puts "🧹 Cleaned up #{deleted_count} old load test devices"
  end
rescue => e
  puts "⚠️  Could not clean up old devices: #{e.message}"
end

# Clean up old load test users (but keep the main test user)
begin
  old_test_users = User.where("email LIKE 'loadtest%@example.com' AND created_at < ?", 1.hour.ago)
  deleted_users = old_test_users.count
  old_test_users.destroy_all
  
  if deleted_users > 0
    puts "🧹 Cleaned up #{deleted_users} old load test users"
  end
rescue => e
  puts "⚠️  Could not clean up old users: #{e.message}"
end

puts "🌱 Load testing seed data created successfully!"
puts "📊 Summary:"
puts "  - Test user: #{test_user.email}"
puts "  - Device types: #{DeviceType.count}"
puts "  - Test devices: #{test_user.devices.count}"
puts "  - Sensor types: #{SensorType.count}"
puts "  - Test products: #{Product.where(device_type: [environmental_monitor, liquid_monitor]).count}"
if defined?(Preset)
  puts "  - Predefined presets: #{Preset.where(is_user_defined: false).count}"
end
puts ""
puts "ℹ️  Use these credentials for manual testing:"
puts "  Email: test@example.com"
puts "  Password: password"