puts "Seeding presets..."

env_monitor = DeviceType.find_by!(name: 'Environmental Monitor V1')
liquid_monitor = DeviceType.find_by!(name: 'Liquid Monitor V1')

# Update Environmental Monitor V1 configuration
env_monitor.update!(
  configuration: {
    "payload_example" => {
      "hum" => 75.2,
      "temp" => 23.5,
      "press" => 1013.2,
      "spray" => { "state" => "off", "duration" => 0, "frequency" => 0 },
      "lights" => "off"
    },
    "supported_actuators" => {
      "lights" => { "commands" => ["on", "off", "schedule"], "payload_key" => "lights" },
      "spray" => { "commands" => ["on", "off", "spray_cycle"], "payload_key" => "spray" } # Rename actuator to "spray"
    },
    "supported_sensor_types" => {
      "Humidity Sensor" => { "unit" => "%", "required" => true, "payload_key" => "hum", "display_order" => 2 },
      "Pressure Sensor" => { "unit" => "Bar", "required" => true, "payload_key" => "press", "display_order" => 3 },
      "Temperature Sensor" => { "unit" => "°C", "required" => true, "payload_key" => "temp", "display_order" => 1 }
    }
  }
)

# Device 1 Presets (Environmental Monitor V1)
Preset.find_or_create_by!(device_type: env_monitor, name: 'Cannabis', is_user_defined: false) do |p|
  p.settings = {
    lights: { on_at: '08:00hrs', off_at: '20:00hrs' },
    spray: { on_for: 10, off_for: 30 }
  }
end
Preset.find_or_create_by!(device_type: env_monitor, name: 'Chili', is_user_defined: false) do |p|
  p.settings = {
    lights: { on_at: '06:00hrs', off_at: '18:00hrs' },
    spray: { on_for: 5, off_for: 60 }
  }
end

# Device 2 Presets (Liquid Monitor V1) - unchanged
1.upto(10) do |i|
  Preset.find_or_create_by!(device_type: liquid_monitor, name: "Preset #{i}", is_user_defined: false) do |p|
    p.settings = {
      pump1: { duration: i % 2 == 0 ? 5 : 0 },
      pump2: { duration: i % 3 == 0 ? 10 : 0 },
      pump3: { duration: i % 4 == 0 ? 15 : 0 },
      pump4: { duration: i % 5 == 0 ? 20 : 0 },
      pump5: { duration: i % 6 == 0 ? 25 : 0 }
    }
  end
end

puts "Created #{Preset.count} presets"