# lib/tasks/stripe.rake
namespace :stripe do
  desc 'Create Stripe products and prices for seeded plans and products'
  task create_products: :environment do
    require 'stripe'
    Stripe.api_key = Rails.application.credentials.stripe[:secret_key]
    
    Plan.find_each do |plan|
      stripe_product = Stripe::Product.create(name: plan.name, description: plan.description)
      
      monthly_price = Stripe::Price.create(
        unit_amount: (plan.monthly_price * 100).to_i,
        currency: 'usd',
        recurring: { interval: 'month' },
        product: stripe_product.id
      )
      
      yearly_price = Stripe::Price.create(
        unit_amount: (plan.yearly_price * 100).to_i,
        currency: 'usd',
        recurring: { interval: 'year' },
        product: stripe_product.id
      )
      
      plan.update!(stripe_monthly_price_id: monthly_price.id, stripe_yearly_price_id: yearly_price.id)
    end
    
    Product.find_each do |product|
      stripe_product = Stripe::Product.create(name: product.name, description: product.description)
      
      price = Stripe::Price.create(
        unit_amount: (product.price * 100).to_i,
        currency: 'usd',
        product: stripe_product.id
      )
      
      product.update!(stripe_price_id: price.id)
    end
    
    puts 'Stripe products and prices created successfully!'
  end
end
