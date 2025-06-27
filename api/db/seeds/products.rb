# db/seeds/products.rb
puts 'Seeding products...'

# Devices
env_monitor = DeviceType.find_by!(name: 'Environmental Monitor V1')
Product.find_or_create_by!(name: 'Environmental Monitoring Kit V1') do |p|
  p.description = 'Complete environmental monitoring solution with temperature, humidity, and pressure sensors'
  p.detailed_description = 'Professional-grade environmental monitoring system perfect for greenhouses, grow rooms, and indoor farming. Features real-time monitoring, mobile alerts, and cloud data logging. Includes all sensors, mounting hardware, and 1-year warranty.'
  p.price = 299.99
  p.device_type = env_monitor
  p.active = true
  p.featured = true
  p.stock_quantity = 15
  p.low_stock_threshold = 3
end

liquid_monitor = DeviceType.find_by!(name: 'Liquid Monitor V1')
Product.find_or_create_by!(name: 'Liquid Monitoring Kit V1') do |p|
  p.description = 'Professional liquid monitoring system with pH and EC sensors and a temperature sensor'
  p.detailed_description = 'Advanced hydroponic monitoring system with precision pH and EC sensors. Includes automatic calibration, data logging, and mobile notifications. Perfect for serious growers who demand accuracy and reliability.'
  p.price = 199.99
  p.device_type = liquid_monitor
  p.active = true
  p.featured = true
  p.stock_quantity = 12
  p.low_stock_threshold = 2
end

# Accessories (non-device products)
Product.find_or_create_by!(name: 'Calibration Solution Kit') do |p|
  p.description = 'pH and EC calibration solutions'
  p.detailed_description = 'Professional calibration solutions for maintaining sensor accuracy. Includes pH 4.0, pH 7.0, pH 10.0, and EC 1413 μS/cm solutions. Essential for accurate readings and sensor longevity.'
  p.price = 49.99
  p.active = true
  p.featured = false
  p.stock_quantity = 25
  p.low_stock_threshold = 5
end

# Additional accessories
Product.find_or_create_by!(name: 'Sensor Cleaning Kit') do |p|
  p.description = 'Complete sensor maintenance and cleaning kit'
  p.detailed_description = 'Keep your sensors in perfect condition with our professional cleaning kit. Includes cleaning solutions, soft brushes, and microfiber cloths specifically designed for delicate sensor equipment.'
  p.price = 29.99
  p.active = true
  p.featured = false
  p.stock_quantity = 30
  p.low_stock_threshold = 8
end

Product.find_or_create_by!(name: 'Mounting Hardware Set') do |p|
  p.description = 'Universal mounting brackets and hardware'
  p.detailed_description = 'Versatile mounting solution for all XSpaceGrow devices. Includes adjustable brackets, screws, anchors, and cable management accessories. Compatible with all monitor types.'
  p.price = 24.99
  p.active = true
  p.featured = false
  p.stock_quantity = 20
  p.low_stock_threshold = 5
end

puts "Created #{Product.count} products"