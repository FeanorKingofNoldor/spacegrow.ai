# db/seeds/plans.rb
puts 'Seeding plans...'

# Basic Plan
Plan.find_or_create_by!(name: 'Basic') do |plan|
  plan.monthly_price = 10.00
  plan.yearly_price = 96.00  # 20% off monthly
  plan.device_limit = 2
  plan.description = 'Basic plan with 2 devices included'
end

# Professional Plan
Plan.find_or_create_by!(name: 'Professional') do |plan|
  plan.monthly_price = 30.00
  plan.yearly_price = 288.00  # 20% off monthly
  plan.device_limit = 4
  plan.description = 'Professional plan with 4 devices included and advanced features'
end

puts "Created #{Plan.count} plans"