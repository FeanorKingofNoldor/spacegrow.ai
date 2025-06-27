# config/initializers/redis.rb
require 'redis'

redis_config = {
  host: ENV.fetch('REDIS_HOST', 'localhost'),
  port: ENV.fetch('REDIS_PORT', 6379),
  db: ENV.fetch('REDIS_DB', 0)
}

# Global Redis connection
$redis = Redis.new(redis_config)
