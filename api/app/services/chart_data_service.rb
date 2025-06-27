class ChartDataService
  def initialize(device_sensor_id, mode: :current)
    @device_sensor_id = device_sensor_id
    @mode = mode
  end

  VALID_INTERVALS = {
    '5 minutes' => 'minute',
    'hourly' => 'hour',
    'daily' => 'day',
    'weekly' => 'week',
    'monthly' => 'month'
  }.freeze

  def fetch_data_points
    Rails.logger.info "Fetching data for sensor #{@device_sensor_id}, mode: #{@mode}"
    data = case @mode
           when :history_24h
             fetch_historical_data(24.hours.ago, 'minute')
           when :history_7d
             fetch_historical_data(7.days.ago, '5 minutes')
           when :history_3m
             fetch_historical_data(3.months.ago, 'hour')
           else
             fetch_live_data
           end
    Rails.logger.info "Fetched #{data.length} data points for sensor #{@device_sensor_id}"
    data
  rescue => e
    Rails.logger.error "Error fetching data for sensor #{@device_sensor_id}: #{e.message}"
    [] # Return empty array on error
  end

  private

  def fetch_live_data
    latest = SensorDatum.where(device_sensor_id: @device_sensor_id, is_valid: true)
                        .order(timestamp: :desc)
                        .limit(1)
                        .pluck(:timestamp, :value)
    latest.empty? ? [] : [[latest.first[0].utc.iso8601, latest.first[1]]]
  end

  def fetch_historical_data(time_range, grouping_interval)
    pg_interval = VALID_INTERVALS[grouping_interval] || grouping_interval
    data = SensorDatum.where(device_sensor_id: @device_sensor_id, is_valid: true)
                      .where('timestamp > ?', time_range)
                      .group("DATE_TRUNC('#{pg_interval}', timestamp)")
                      .average(:value)
                      .sort_by(&:first)
    data.map { |timestamp, avg_value| [timestamp.utc.iso8601, avg_value] }
  end
end