# db/seeds.rb
puts "Starting database seeding..."
Rails.application.config.seeding = true
# Load seed modules in specific order based on dependencies
%w[
  sensor_types
  device_types
  presets
  plans
  products
  users
].each do |seed|
  puts "Seeding #{seed}..."
  load Rails.root.join('db', 'seeds', "#{seed}.rb")
  puts "✓ #{seed} seeded"
end
Rails.application.config.seeding = false

puts "Database seeding completed!"