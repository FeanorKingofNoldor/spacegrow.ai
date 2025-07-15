module Infrastructure 
  class RateLimiter < ApplicationService
    RATE_LIMIT = 100
    TIME_WINDOW = 60
    BURST_LIMIT = 200
    BURST_WINDOW = 300

    def initialize(device_id, burst_rate: RATE_LIMIT, burst_period: TIME_WINDOW, sustained_rate: BURST_LIMIT, sustained_period: BURST_WINDOW)
      @device_id = device_id
      @burst_rate = burst_rate
      @burst_period = burst_period
      @sustained_rate = sustained_rate
      @sustained_period = sustained_period
      Rails.logger.debug("Initialized RateLimiter for device_id: #{@device_id}")
    end

    def within_limit?
      current = current_count
      burst = burst_count
      Rails.logger.debug("Checking limits for device_id: #{@device_id} | Current count: #{current} | Burst count: #{burst}")
      current <= @burst_rate && burst <= @sustained_rate
    end

    def limit!
      increment
      within_limit?  # Returns true/false
    end

    def increment
      time = Time.now.to_i
      unique_id = SecureRandom.uuid
      Rails.logger.debug("Incrementing count for device_id: #{@device_id} | Time: #{time} | Unique ID: #{unique_id}")
      $redis.multi do |multi|
        multi.zadd(standard_key, time, "#{time}:#{unique_id}")
        multi.zadd(burst_key, time, "#{time}:#{unique_id}")
        multi.zremrangebyscore(standard_key, '-inf', time - @burst_period)
        multi.zremrangebyscore(burst_key, '-inf', time - @sustained_period)
      end
    end

    def current_count
      now = Time.now.to_i
      cutoff = now - @burst_period
      count = $redis.zcount(standard_key, cutoff, '+inf')
      Rails.logger.debug("Current count for device_id: #{@device_id} | Count: #{count} | Cutoff: #{cutoff}")
      count
    end

    def burst_count
      now = Time.now.to_i
      cutoff = now - @sustained_period
      count = $redis.zcount(burst_key, cutoff, '+inf')
      Rails.logger.debug("Burst count for device_id: #{@device_id} | Count: #{count} | Cutoff: #{cutoff}")
      count
    end

    private

    def standard_key
      "rate_limit:device:#{@device_id}:requests"
    end

    def burst_key
      "rate_limit:device:#{@device_id}:burst"
    end
  end
end