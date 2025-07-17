# lib/tasks/load_test.rake - Load Testing Rails Tasks

namespace :load_test do
  desc "Prepare the system for load testing"
  task setup: :environment do
    puts "🔧 Setting up load testing environment..."
    
    # Check if we're in a safe environment
    unless Rails.env.development? || Rails.env.test?
      puts "❌ Load testing setup only allowed in development or test environments"
      exit 1
    end
    
    # Set load testing environment variable
    ENV['LOAD_TESTING'] = 'true'
    
    # Check Redis connection (handle different cache store types)
    begin
      if Rails.cache.respond_to?(:redis)
        Rails.cache.redis.ping
        puts "✅ Redis connection verified"
      elsif Rails.cache.respond_to?(:clear)
        Rails.cache.clear
        puts "✅ Cache store available (not Redis)"
      else
        puts "⚠️  No cache store available"
      end
    rescue => e
      puts "⚠️  Cache connection failed: #{e.message}"
      puts "   Rate limiting may not work properly"
    end
    
    # Create the seed file path
    seed_file = Rails.root.join('db', 'seeds', 'load_test_seeds.rb')
    
    # Create seeds directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(seed_file))
    
    # Check if seed file exists
    unless File.exist?(seed_file)
      puts "⚠️  Load test seed file not found at #{seed_file}"
      puts "   Creating basic test data instead..."
      
      # Create basic test data inline
      test_user = User.find_or_create_by(email: 'test@example.com') do |user|
        user.password = 'password'
        user.password_confirmation = 'password'
        user.role = 'user'
        user.timezone = 'UTC' if user.respond_to?(:timezone)
      end
      puts "✅ Test user created: #{test_user.email}"
      
      # Create basic device type if needed
      if defined?(DeviceType)
        device_type = DeviceType.find_or_create_by(name: 'Test Device Type') do |dt|
          dt.description = 'Basic test device type for load testing'
        end
        puts "✅ Basic device type created: #{device_type.name}"
      end
      
    else
      # Run seed data
      puts "🌱 Creating test data from seed file..."
      load seed_file
    end
    
    # Clear any existing rate limit data
    if defined?(Rack::Attack)
      begin
        if Rack::Attack.cache.respond_to?(:clear)
          Rack::Attack.cache.clear
          puts "✅ Cleared rate limiting cache"
        end
      rescue => e
        puts "⚠️  Could not clear rate limiting cache: #{e.message}"
      end
    end
    
    puts "✅ Load testing environment prepared!"
    puts ""
    puts "ℹ️  Next steps:"
    puts "  1. Start Rails server: LOAD_TESTING=true rails server"
    puts "  2. Run load tests: ./run-tests-load.sh"
    puts "  3. Clean up: rake load_test:cleanup"
  end
  
  desc "Clean up after load testing"
  task cleanup: :environment do
    puts "🧹 Cleaning up load testing data..."
    
    # Remove test devices created during load testing
    test_devices = Device.where("name LIKE 'Load Test Device%'")
    deleted_devices = test_devices.count
    test_devices.destroy_all
    puts "🗑  Deleted #{deleted_devices} load test devices"
    
    # Remove test users created during load testing (keep main test user)
    test_users = User.where("email LIKE 'loadtest%@example.com'")
    deleted_users = test_users.count
    test_users.destroy_all
    puts "🗑  Deleted #{deleted_users} load test users"
    
    # Clear rate limiting cache
    if defined?(Rack::Attack)
      begin
        Rack::Attack.cache.store.clear
        puts "✅ Cleared rate limiting cache"
      rescue => e
        puts "⚠  Could not clear rate limiting cache: #{e.message}"
      end
    end
    
    # Clear any session data
    begin
      Rails.cache.clear
      puts "✅ Cleared application cache"
    rescue => e
      puts "⚠  Could not clear application cache: #{e.message}"
    end
    
    puts "✅ Load testing cleanup completed!"
  end
  
  desc "Run a quick load test simulation"
  task simulate: :environment do
    puts "🚀 Running load test simulation..."
    
    # Create a test user
    user = User.find_or_create_by(email: 'simulator@example.com') do |u|
      u.password = 'password'
      u.password_confirmation = 'password'
    end
    
    # Create some test devices
    5.times do |i|
      device = user.devices.create!(
        name: "Simulator Device #{i}",
        device_type: DeviceType.first || DeviceType.create!(name: 'Test Type'),
        status: 'active',
        alert_status: 'normal'
      )
      
      # Create sensors
      2.times do |j|
        sensor_type = SensorType.first || SensorType.create!(
          name: 'test_sensor',
          unit: 'unit',
          min_value: 0,
          max_value: 100,
          normal_min: 20,
          normal_max: 80,
          error_low_min: 0,
          error_low_max: 10,
          warning_low_min: 10,
          warning_low_max: 20,
          warning_high_min: 80,
          warning_high_max: 90,
          error_high_min: 90,
          error_high_max: 100
        )
        
        device.sensors.create!(
          sensor_type: sensor_type,
          status: 'ok',
          last_reading: rand(20..80)
        )
      end
    end
    
    puts "✅ Created simulation data:"
    puts "  - User: #{user.email}"
    puts "  - Devices: #{user.devices.count}"
    puts "  - Total sensors: #{user.devices.sum { |d| d.sensors.count }}"
    
    # Simulate some API calls
    puts "🔄 Simulating API load..."
    
    require 'net/http'
    require 'uri'
    require 'json'
    
    base_url = 'http://localhost:3000'
    
    # Login to get token
    login_uri = URI("#{base_url}/api/v1/auth/login")
    http = Net::HTTP.new(login_uri.host, login_uri.port)
    
    login_request = Net::HTTP::Post.new(login_uri)
    login_request['Content-Type'] = 'application/json'
    login_request.body = {
      user: {
        email: user.email,
        password: 'password'
      }
    }.to_json
    
    begin
      login_response = http.request(login_request)
      
      if login_response.code == '200'
        token = JSON.parse(login_response.body)['token']
        puts "✅ Authentication successful"
        
        # Make some API calls
        endpoints = [
          '/api/v1/frontend/dashboard',
          '/api/v1/frontend/devices'
        ]
        
        endpoints.each do |endpoint|
          uri = URI("#{base_url}#{endpoint}")
          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "Bearer #{token}"
          
          response = http.request(request)
          puts "  #{endpoint}: #{response.code}"
        end
        
      else
        puts "❌ Authentication failed: #{login_response.code}"
      end
      
    rescue => e
      puts "❌ Simulation failed: #{e.message}"
      puts "   Make sure Rails server is running on #{base_url}"
    end
    
    puts "✅ Load test simulation completed!"
  end
  
  desc "Check system readiness for load testing"
  task check: :environment do
    puts "🔍 Checking system readiness for load testing..."
    
    checks = []
    
    # Check Rails environment
    if Rails.env.development? || Rails.env.test?
      checks << { name: "Rails Environment", status: "✅ Safe (#{Rails.env})" }
    else
      checks << { name: "Rails Environment", status: "❌ Unsafe (#{Rails.env})" }
    end
    
    # Check Redis
    begin
      Rails.cache.redis.ping
      checks << { name: "Redis Connection", status: "✅ Connected" }
    rescue
      checks << { name: "Redis Connection", status: "❌ Not connected" }
    end
    
    # Check database
    begin
      User.count
      checks << { name: "Database Connection", status: "✅ Connected" }
    rescue
      checks << { name: "Database Connection", status: "❌ Not connected" }
    end
    
    # Check test data
    test_user = User.find_by(email: 'test@example.com')
    if test_user
      checks << { name: "Test User", status: "✅ Available (#{test_user.email})" }
    else
      checks << { name: "Test User", status: "❌ Not found" }
    end
    
    # Check device types
    if DeviceType.count > 0
      checks << { name: "Device Types", status: "✅ Available (#{DeviceType.count})" }
    else
      checks << { name: "Device Types", status: "❌ None found" }
    end
    
    # Check rate limiting status
    if ENV['LOAD_TESTING'] == 'true'
      checks << { name: "Rate Limiting", status: "✅ Disabled for testing" }
    else
      checks << { name: "Rate Limiting", status: "⚠  Enabled (may interfere)" }
    end
    
    # Display results
    puts ""
    puts "System Readiness Report:"
    puts "=" * 40
    
    all_good = true
    checks.each do |check|
      puts "#{check[:name].ljust(25)} #{check[:status]}"
      all_good = false if check[:status].include?("❌")
    end
    
    puts "=" * 40
    
    if all_good
      puts "✅ System is ready for load testing!"
    else
      puts "❌ System has issues that need to be addressed"
      puts ""
      puts "🔧 To fix issues:"
      puts "  - Run: rake load_test:setup"
      puts "  - Start server: LOAD_TESTING=true rails server"
    end
  end
  
  desc "Monitor system during load testing"
  task monitor: :environment do
    puts "📊 Starting load test monitoring..."
    puts "Press Ctrl+C to stop monitoring"
    
    trap('INT') do
      puts "\n📊 Monitoring stopped"
      exit
    end
    
    loop do
      system('clear') || system('cls')
      
      puts "📊 SpaceGrow Load Test Monitor"
      puts "=" * 50
      puts "Time: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
      puts ""
      
      # Database stats
      begin
        puts "📊 Database:"
        puts "  Users: #{User.count}"
        puts "  Devices: #{Device.count}"
        puts "  Active devices: #{Device.where(status: 'active').count}"
        puts ""
      rescue => e
        puts "❌ Database error: #{e.message}"
      end
      
      # Memory usage (if possible)
      begin
        if RUBY_PLATFORM.include?('linux')
          memory_info = `cat /proc/meminfo | grep MemAvailable`.strip
          puts "💾 System:"
          puts "  #{memory_info}"
        elsif RUBY_PLATFORM.include?('darwin')
          # macOS memory check
          memory_pressure = `memory_pressure 2>/dev/null | head -1`.strip
          puts "💾 System:"
          puts "  #{memory_pressure}" unless memory_pressure.empty?
        end
        puts ""
      rescue
        # Skip if system tools not available
      end
      
      # Rails cache stats
      begin
        if defined?(Rack::Attack)
          puts "🛡  Rate Limiting:"
          puts "  Status: #{Rack::Attack.enabled? ? 'Enabled' : 'Disabled'}"
        end
        puts ""
      rescue
        # Skip if Rack::Attack not available
      end
      
      puts "ℹ  Refreshing in 5 seconds..."
      sleep 5
    end
  end
end