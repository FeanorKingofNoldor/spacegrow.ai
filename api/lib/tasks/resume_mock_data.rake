namespace :mock_data do
  desc 'Resume sensor data generation and command polling for an existing user'
  task :resume, [:email] => :environment do |_, args|
    require 'net/http'
    require 'json'

    email = args[:email]
    if email.nil? || email.strip.empty?
      puts "❌ Email argument is required. Usage: rake mock_data:resume['user@example.com']"
      exit 1
    end

    user = User.find_by(email: email)
    if user.nil?
      puts "❌ User with email '#{email}' not found."
      exit 1
    end

    puts "✅ Found User: #{user.email} (Timezone: #{user.timezone})"
    devices = user.devices
    if devices.empty?
      puts "⚠️ No devices found for user #{user.email}."
      exit 1
    end

    sensors = devices.flat_map(&:device_sensors)
    puts "✅ Found #{sensors.count} sensors across #{devices.count} devices"

    states = %i[normal warning_low warning_high error_low error_high]
    state_index = 0

    puts "🚀 Resuming sensor data simulation and command polling for user #{user.email}..."

    # Initial sensor data send after 5-second delay
    sleep 5
    puts "=== Sending Initial Sensor Data (#{Time.current}) ==="
    devices.each do |device|
      send_sensor_data(device, states[state_index])
    end
    state_index = (state_index + 1) % states.length
    last_sensor_data_time = Time.current

    # Define fetch_and_execute_commands with simulate_command_execution inline
    def fetch_and_execute_commands(device)
      sleep 1
      puts "[#{Time.current}] Polling commands for device #{device.id} (#{device.name})"
      # Updated to ESP32 namespace
      uri = URI("http://localhost:3000/api/v1/esp32/devices/commands")
      token = device.activation_token.token
      headers = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.path, headers)
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        commands = data['commands'] || []
        if commands.empty?
          puts "[#{Time.current}] No pending commands for device #{device.id}"
        else
          commands.each do |command|
            command_id = command['id']
            puts "[#{Time.current}] 📥 Fetched command for device #{device.id}: #{command['command']} (ID: #{command_id})"
            if command_id.nil?
              puts "[#{Time.current}] ❌ Missing command_id: #{command.inspect}"
              next
            end
            # Updated to ESP32 namespace
            uri_status = URI("http://localhost:3000/api/v1/esp32/devices/command_status")
            http_status = Net::HTTP.new(uri_status.host, uri_status.port)
            request_status = Net::HTTP::Post.new(uri_status.path, headers)
            request_status.body = { command_id: command_id, status: 'sent', message: 'Command received' }.to_json
            response_status = http_status.request(request_status)
            puts "[#{Time.current}] Marked command #{command_id} as 'sent': #{response_status.code}"

            # Inline simulation
            success = [true, false].sample
            status = success ? 'executed' : 'failed'
            message = success ? 'Device Updated Successfully' : 'Device Update Failed'
            Rails.logger.info "Simulated command execution for device #{device.id}: #{command['command']} - Status: #{status}"
            request_status = Net::HTTP::Post.new(uri_status.path, headers)
            request_status.body = { command_id: command_id, status: status, message: message }.to_json
            response_status = http_status.request(request_status)
            if response_status.is_a?(Net::HTTPSuccess)
              puts "[#{Time.current}] #{success ? '✅' : '❌'} Simulated command #{command_id} as '#{status}' (Response: #{response_status.code})"
            else
              puts "[#{Time.current}] ❌ Failed to report status for command #{command_id}: #{response_status.code} - #{response_status.body}"
            end
          end
        end
      else
        puts "[#{Time.current}] ❌ Failed to fetch commands for device #{device.id}: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "[#{Time.current}] ❌ Error fetching commands for device #{device.id}: #{e.message}"
    end

    # Private method for sending sensor data (unchanged)
    def send_sensor_data(device, state)
      sensor_data_payload = { timestamp: Time.current.to_i }
      device.device_sensors.each do |sensor|
        sensor_type = sensor.sensor_type
        device_type_config = device.device_type.configuration['supported_sensor_types'] || {}
        unless device_type_config.key?(sensor_type.name)
          puts "⚠️ Device #{device.id} - Sensor #{sensor_type.name} missing configuration. Skipping..."
          next
        end
        payload_key = device_type_config[sensor_type.name]['payload_key']
        range = case state
                when :normal then sensor_type.normal_min..sensor_type.normal_max
                when :warning_low then sensor_type.warning_low_min..sensor_type.warning_low_max
                when :warning_high then sensor_type.warning_high_min..sensor_type.warning_high_max
                when :error_low then sensor_type.error_low_min..sensor_type.error_low_max
                when :error_high then sensor_type.error_high_min..sensor_type.error_high_max
                end
        value = rand(range)
        sensor_data_payload[payload_key] = value
        range_category = case value
                         when sensor_type.error_low_min..sensor_type.error_low_max then 'Error Low'
                         when sensor_type.warning_low_min..sensor_type.warning_low_max then 'Warning Low'
                         when sensor_type.normal_min..sensor_type.normal_max then 'Normal'
                         when sensor_type.warning_high_min..sensor_type.warning_high_max then 'Warning High'
                         when sensor_type.error_high_min..sensor_type.error_high_max then 'Error High'
                         else 'Out of Range'
                         end
        puts "   ↳ Sensor: #{sensor_type.name} | Value: #{value} | Range: #{range_category}"
      end
      # Updated to ESP32 namespace
      uri = URI('http://localhost:3000/api/v1/esp32/sensor_data')
      token = device.activation_token.token
      headers = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = sensor_data_payload.to_json
      response = http.request(request)
      puts "[#{Time.current}] ✅ Device #{device.id} - Sensor Data Sent Successfully" if response.is_a?(Net::HTTPSuccess)
      unless response.is_a?(Net::HTTPSuccess)
        puts "[#{Time.current}] ❌ Device #{device.id} - API Error: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "[#{Time.current}] ❌ Error sending sensor data for device #{device.id}: #{e.message}"
    end

    # Main loop
    loop do
      current_time = Time.current

      # Command polling every 5 seconds
      devices.each do |device|
        fetch_and_execute_commands(device)
      end

      # Sensor data every 1 minute
      if current_time - last_sensor_data_time >= 60
        puts "=== Sending Sensor Data (#{current_time}) ==="
        devices.each do |device|
          send_sensor_data(device, states[state_index])
        end
        state_index = (state_index + 1) % states.length
        last_sensor_data_time = current_time
      end

      sleep 5
    end
  end
end