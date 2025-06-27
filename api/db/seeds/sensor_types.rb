# db/seeds/sensor_types.rb
puts "Seeding sensor types..."
SensorType.seed_defaults!
puts "Created #{SensorType.count} sensor types"