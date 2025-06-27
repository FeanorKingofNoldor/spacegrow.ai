# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from your Next.js frontend
    origins 'http://localhost:3001', 'localhost:3001', '127.0.0.1:3001'

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
  
  # Allow requests from same origin (for API testing)
  allow do
    origins 'http://localhost:3000', 'localhost:3000', '127.0.0.1:3000'

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end