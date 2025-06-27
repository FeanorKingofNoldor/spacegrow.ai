puts "Seeding device types..."

# Device 1: Environmental Monitor V1
env_monitor = DeviceType.find_or_initialize_by(name: 'Environmental Monitor V1')
env_monitor.description = 'Environmental monitoring and control device'
env_monitor.configuration = {
  supported_sensor_types: {
    'Temperature Sensor' => { required: true, payload_key: 'temp', unit: '°C', display_order: 1 },
    'Humidity Sensor' => { required: true, payload_key: 'hum', unit: '%', display_order: 2 },
    'Pressure Sensor' => { required: true, payload_key: 'press', unit: 'Bar', display_order: 3 }
  },
  supported_actuators: {
    'lights' => { payload_key: 'lights', commands: ['on', 'off', 'schedule'] },
    'spray_cycle' => { payload_key: 'spray', commands: ['on', 'off', 'set_frequency', 'set_duration'] }
  },
  payload_example: {
    temp: 23.5, hum: 75.2, press: 1013.2,
    lights: 'off', spray: { frequency: 0, duration: 0, state: 'off' }
  }
}
env_monitor.save!

# Device 2: Liquid Monitor V1
liquid_monitor = DeviceType.find_or_initialize_by(name: 'Liquid Monitor V1')
liquid_monitor.description = 'Liquid monitoring and nutrient dosing device'
liquid_monitor.configuration = {
  supported_sensor_types: {
    'pH Sensor' => { required: true, payload_key: 'ph', unit: 'pH', display_order: 1 },
    'EC Sensor' => { required: true, payload_key: 'ec', unit: 'mS/cm', display_order: 2 },
    'Temperature Sensor' => { required: true, payload_key: 'temp', unit: '°C', display_order: 3 }
  },
  supported_actuators: {
    'pump1' => { payload_key: 'pump1', commands: ['dose', 'prime', 'clean'] },
    'pump2' => { payload_key: 'pump2', commands: ['dose', 'prime', 'clean'] },
    'pump3' => { payload_key: 'pump3', commands: ['dose', 'prime', 'clean'] },
    'pump4' => { payload_key: 'pump4', commands: ['dose', 'prime', 'clean'] },
    'pump5' => { payload_key: 'pump5', commands: ['dose', 'prime', 'clean'] }
  },
  payload_example: {
    ph: 5.0, ec: 2.5, temp: 18.0,
    pump1: 'idle', pump2: 'idle', pump3: 'idle', pump4: 'idle', pump5: 'idle'
  }
}
liquid_monitor.save!

puts "Created or updated #{DeviceType.count} device types"