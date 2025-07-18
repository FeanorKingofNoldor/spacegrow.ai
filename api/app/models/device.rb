# app/models/device.rb
class Device < ApplicationRecord
  include Suspendable  # ✅ Extract suspension logic to concern
  
  # ✅ NEW: Include admin concerns
  include AdminSearchable
  include AdminAnalytics
  include AdminAlertable

  belongs_to :user
  belongs_to :order, optional: true
  belongs_to :device_type
  belongs_to :activation_token, class_name: 'DeviceActivationToken', optional: true
  belongs_to :current_preset, class_name: 'Preset', optional: true
  
  has_many :device_sensors, dependent: :destroy
  has_many :sensor_data, through: :device_sensors
  has_many :sensor_types, through: :device_sensors
  has_many :presets, dependent: :destroy
  has_many :command_logs, dependent: :destroy
  has_many :subscription_devices, dependent: :destroy
  has_many :subscriptions, through: :subscription_devices

  validates :name, presence: true, length: { maximum: 255 }
  validates :uuid, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending active suspended disabled] }
  validates :alert_status, inclusion: { in: %w[no_data normal warning error] }

  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  before_create :generate_uuid, :generate_api_key
  after_update :validate_sensor_types, if: :saved_change_to_device_type_id?
  
  # ✅ UPDATED: Use throttled broadcasting for connection status changes
  after_update_commit :broadcast_connection_status_throttled, 
                     if: :saved_change_to_last_connection?

  # ===== ADMIN SCOPES FOR DEVICE FLEET MANAGEMENT =====
  
  scope :offline_devices, ->(hours = 1) { where(last_connection: ..hours.hours.ago) }
  scope :error_devices, -> { where(status: 'error') }
  scope :never_connected, -> { where(last_connection: nil) }
  scope :recently_connected, ->(minutes = 10) { where(last_connection: minutes.minutes.ago..) }
  scope :healthy_devices, -> { recently_connected.where.not(status: 'error') }
  scope :warning_devices, -> { where(last_connection: 10.minutes.ago..1.hour.ago) }
  scope :critical_devices, -> { offline_devices.or(error_devices) }
  scope :by_device_type, ->(type_name) { joins(:device_type).where(device_types: { name: type_name }) }
  scope :by_owner_plan, ->(plan_name) { joins(user: { subscription: :plan }).where(plans: { name: plan_name }) }
  scope :over_limit_devices, -> { joins(:user).where('(SELECT COUNT(*) FROM devices d2 WHERE d2.user_id = devices.user_id) > (SELECT device_limit FROM users WHERE users.id = devices.user_id)') }
  scope :underutilized_users, -> { joins(:user).group('users.id').having('COUNT(devices.id) < (users.device_limit * 0.5)') }
  scope :recent_registrations, ->(days = 7) { where(created_at: days.days.ago..Time.current) }
  scope :frequent_disconnects, -> { where('last_connection < ? AND updated_at > ?', 6.hours.ago, 24.hours.ago) }
  scope :long_running, ->(days = 30) { where('created_at < ?', days.days.ago) }
  scope :by_firmware_version, ->(version) { where(firmware_version: version) }
  scope :needs_update, -> { where('firmware_version IS NULL OR firmware_version < ?', latest_firmware_version) }
  scope :geographic_region, ->(region) { where("location ->> 'region' = ?", region) }

  # ✅ KEEP: Device-specific methods
  def update_connection!
    Rails.logger.info "🔗 [Device##{id}] Updating connection timestamp"
    update!(last_connection: Time.current)
  end

  def is_online?
    timeout = 10.minutes
    last_connection && last_connection > Time.current - timeout
  end

  def connection_status
    is_online? ? 'online' : 'offline'
  end

  def status_class
    is_online? ? 
      'bg-green-500/10 border-green-500/50' : 
      'bg-red-500/10 border-red-500/50'
  end

  def generate_api_key!
    self.api_key = SecureRandom.hex(32)
    save!
  end

  # ✅ KEEP: Status checking methods (now also defined in concern)
  def pending?
    status == 'pending'
  end

  def active?
    status == 'active'
  end

  def disabled?
    status == 'disabled'
  end

  # ✅ NEW: Disable/enable methods
  def disable!(reason: 'Manual disable')
    update!(
      status: 'disabled',
      disabled_at: Time.current,
      disabled_reason: reason,
      previous_status: status_was
    )
  end

  def enable!
    new_status = previous_status == 'suspended' ? 'suspended' : 'active'
    update!(
      status: new_status,
      disabled_at: nil,
      disabled_reason: nil,
      previous_status: nil
    )
  end

  # ===== ADMIN HELPER METHODS =====
  
  def admin_summary
    {
      id: id,
      name: name,
      status: status,
      device_type: device_type&.name,
      owner: user.display_name,
      owner_email: user.email,
      health_status: admin_health_status,
      connection_status: admin_connection_status,
      last_activity: last_connection,
      uptime_estimate: admin_uptime_estimate,
      alert_level: admin_alert_level,
      created_at: created_at,
      flags: admin_device_flags
    }
  end

  def admin_health_status
    return 'critical' if status == 'error' || never_connected?
    return 'critical' if last_connection && last_connection < 2.hours.ago
    return 'warning' if last_connection && last_connection < 30.minutes.ago
    return 'warning' if status == 'suspended'
    'healthy'
  end

  def admin_connection_status
    return 'never_connected' if last_connection.nil?
    return 'online' if last_connection > 5.minutes.ago
    return 'recently_online' if last_connection > 1.hour.ago
    return 'offline' if last_connection > 6.hours.ago
    'disconnected'
  end

  def admin_uptime_estimate
    return 0 unless last_connection && created_at
    
    total_time = Time.current - created_at
    return 0 if total_time <= 0
    
    # Estimate based on connection patterns
    if last_connection > 1.hour.ago
      ((Time.current - created_at - calculate_estimated_downtime) / total_time * 100).round(1)
    else
      # Device is currently offline, estimate based on historical patterns
      estimated_uptime = total_time * 0.85 # Assume 85% average uptime for offline devices
      (estimated_uptime / total_time * 100).round(1)
    end
  end

  def admin_alert_level
    return 'critical' if status == 'error'
    return 'critical' if never_connected? && created_at < 1.day.ago
    return 'high' if last_connection && last_connection < 2.hours.ago
    return 'medium' if last_connection && last_connection < 30.minutes.ago
    return 'medium' if status == 'suspended'
    'low'
  end

  def admin_device_flags
    flags = []
    flags << 'never_connected' if never_connected?
    flags << 'frequent_disconnects' if frequent_disconnects?
    flags << 'needs_firmware_update' if needs_firmware_update?
    flags << 'over_user_limit' if over_user_device_limit?
    flags << 'high_value_customer' if user.admin_flags.include?('vip_customer')
    flags << 'long_running' if created_at < 90.days.ago
    flags << 'recently_registered' if created_at > 7.days.ago
    flags << 'error_prone' if error_prone_device?
    flags
  end

  def admin_troubleshooting_info
    issues = []
    recommendations = []
    
    if never_connected?
      issues << { 
        type: 'connection', 
        severity: 'critical', 
        description: 'Device has never established connection',
        possible_causes: ['Incorrect activation token', 'Network connectivity issues', 'Device hardware problem']
      }
      recommendations << 'Verify activation token and network settings'
      recommendations << 'Check device power and hardware status'
    end
    
    if status == 'error'
      issues << { 
        type: 'error_state', 
        severity: 'critical', 
        description: 'Device is in error state',
        possible_causes: ['Firmware issue', 'Hardware malfunction', 'Configuration error']
      }
      recommendations << 'Review device logs for error details'
      recommendations << 'Consider firmware update or device reset'
    end
    
    if frequent_disconnects?
      issues << { 
        type: 'connectivity', 
        severity: 'medium', 
        description: 'Device experiences frequent disconnections',
        possible_causes: ['Unstable network', 'Power issues', 'Interference']
      }
      recommendations << 'Check network stability and signal strength'
      recommendations << 'Verify power supply consistency'
    end
    
    if needs_firmware_update?
      issues << { 
        type: 'maintenance', 
        severity: 'low', 
        description: 'Device firmware needs updating',
        possible_causes: ['Outdated firmware version']
      }
      recommendations << 'Schedule firmware update during maintenance window'
    end
    
    {
      issues: issues,
      recommendations: recommendations,
      diagnostic_score: calculate_diagnostic_score(issues),
      last_analyzed: Time.current
    }
  end

  def admin_performance_metrics
    {
      connection_reliability: calculate_connection_reliability,
      average_session_duration: calculate_average_session_duration,
      data_quality_score: calculate_data_quality_score,
      error_frequency: calculate_error_frequency,
      maintenance_score: calculate_maintenance_score
    }
  end

  def admin_owner_context
    {
      owner: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        role: user.role,
        subscription_plan: user.subscription&.plan&.name,
        device_count: user.devices.count,
        device_limit: user.device_limit,
        over_limit: user.devices.count > user.device_limit
      },
      account_health: {
        subscription_status: user.subscription&.status,
        payment_issues: user.orders.where(status: 'payment_failed').recent.any?,
        support_tickets: 0, # Would integrate with support system
        satisfaction_score: 4.2 # Would integrate with feedback system
      }
    }
  end

  def admin_activity_timeline(limit = 10)
    activities = []
    
    # Connection events
    if last_connection
      activities << {
        type: 'connection',
        description: 'Last connected',
        timestamp: last_connection,
        details: { connection_type: 'device_checkin' }
      }
    end
    
    # Status changes (would come from audit log)
    activities << {
      type: 'status_change',
      description: "Status changed to #{status}",
      timestamp: updated_at,
      details: { new_status: status }
    }
    
    # Registration
    activities << {
      type: 'registration',
      description: 'Device registered',
      timestamp: created_at,
      details: { device_type: device_type&.name }
    }
    
    # Recent sensor data (if available)
    if respond_to?(:sensor_data)
      recent_data = sensor_data.order(created_at: :desc).limit(3)
      recent_data.each do |data|
        activities << {
          type: 'sensor_data',
          description: "#{data.sensor_type} reading: #{data.value}#{data.unit}",
          timestamp: data.created_at,
          details: { sensor_type: data.sensor_type, value: data.value }
        }
      end
    end
    
    activities.sort_by { |a| a[:timestamp] }.reverse.first(limit)
  end

  # ===== CLASS METHODS FOR ADMIN ANALYTICS =====
  
  def self.admin_fleet_overview
    {
      total_devices: count,
      by_status: group(:status).count,
      by_type: joins(:device_type).group('device_types.name').count,
      by_health: {
        healthy: healthy_devices.count,
        warning: warning_devices.count,
        critical: critical_devices.count
      },
      connection_stats: {
        online: recently_connected(5).count,
        recently_online: recently_connected(60).count - recently_connected(5).count,
        offline: offline_devices(1).count,
        never_connected: never_connected.count
      },
      fleet_utilization: calculate_fleet_utilization,
      geographic_distribution: analyze_geographic_distribution
    }
  end

  def self.admin_health_trends(days = 7)
    date_range = days.days.ago..Time.current
    
    daily_stats = (0...days).map do |i|
      date = i.days.ago.to_date
      day_start = date.beginning_of_day
      day_end = date.end_of_day
      
      {
        date: date,
        total_devices: where(created_at: ..day_end).count,
        online_devices: where(last_connection: day_start..day_end).count,
        error_devices: where(status: 'error', updated_at: day_start..day_end).count,
        new_registrations: where(created_at: day_start..day_end).count
      }
    end
    
    daily_stats.reverse
  end

  def self.admin_performance_summary
    total = count
    return {} if total == 0
    
    {
      fleet_size: total,
      health_distribution: {
        healthy: (healthy_devices.count.to_f / total * 100).round(1),
        warning: (warning_devices.count.to_f / total * 100).round(1),
        critical: (critical_devices.count.to_f / total * 100).round(1)
      },
      connection_distribution: {
        online: (recently_connected(5).count.to_f / total * 100).round(1),
        offline: (offline_devices(1).count.to_f / total * 100).round(1),
        never_connected: (never_connected.count.to_f / total * 100).round(1)
      },
      average_device_age: calculate_average_device_age,
      firmware_compliance: calculate_firmware_compliance
    }
  end

  def self.admin_maintenance_queue
    {
      needs_firmware_update: needs_update.count,
      frequent_disconnects: frequent_disconnects.count,
      error_devices: error_devices.count,
      never_connected: never_connected.where(created_at: ..1.day.ago).count,
      over_limit_users: joins(:user).where('(SELECT COUNT(*) FROM devices d2 WHERE d2.user_id = devices.user_id) > (SELECT device_limit FROM users WHERE users.id = devices.user_id)').distinct.count(:user_id)
    }
  end

  def self.admin_user_device_distribution
    {
      users_with_devices: joins(:user).distinct.count(:user_id),
      users_at_limit: joins(:user).where('(SELECT COUNT(*) FROM devices d2 WHERE d2.user_id = devices.user_id) >= (SELECT device_limit FROM users WHERE users.id = devices.user_id)').distinct.count(:user_id),
      users_over_limit: joins(:user).where('(SELECT COUNT(*) FROM devices d2 WHERE d2.user_id = devices.user_id) > (SELECT device_limit FROM users WHERE users.id = devices.user_id)').distinct.count(:user_id),
      average_devices_per_user: (count.to_f / joins(:user).distinct.count(:user_id)).round(2),
      device_utilization_by_plan: calculate_utilization_by_plan
    }
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end

  def set_defaults
    self.alert_status ||= 'no_data'
    self.status ||= 'pending'
    self.uuid ||= SecureRandom.uuid
    self.api_key ||= SecureRandom.hex(32)
  end

  def validate_sensor_types
    required_types = device_type.configuration.dig('supported_sensor_types')&.keys || []
    current_types = device_sensors.joins(:sensor_type).pluck('sensor_types.name')
    
    missing_types = required_types - current_types
    extra_types = current_types - required_types
    
    if missing_types.any?
      errors.add(:device_sensors, "Missing required sensor types: #{missing_types.join(', ')}")
    end
    
    if extra_types.any?
      errors.add(:device_sensors, "Unexpected sensor types: #{extra_types.join(', ')}")
    end
  end

  # ✅ NEW: Throttled connection status broadcasting
  def broadcast_connection_status_throttled
    Rails.logger.info "📱 [Device##{id}] Connection status changed, queuing throttled broadcast"
    
    # Create connection status data for batching
    connection_data = {
      device_id: id,
      device_name: name,
      last_connection: last_connection,
      connection_status: connection_status,
      is_online: is_online?,
      device_status: status,
      alert_status: alert_status,
      change_type: 'connection_status_change',
      previous_connection: last_connection_before_last_save
    }
    
    # Use ThrottledBroadcaster for batched device status updates
    WebsocketBroadcasting::ThrottledBroadcaster.broadcast_device_status(id, connection_data)
    
    # Also queue dashboard update for the user
    WebsocketBroadcasting::ThrottledBroadcaster.broadcast_dashboard_update(user.id)
  end

  # ===== ADMIN PRIVATE HELPER METHODS =====
  
  def never_connected?
    last_connection.nil?
  end

  def frequent_disconnects?
    # Simple heuristic: if device was updated recently but last connection is old
    last_connection && last_connection < 6.hours.ago && updated_at > 24.hours.ago
  end

  def needs_firmware_update?
    firmware_version.blank? || (self.class.latest_firmware_version && firmware_version < self.class.latest_firmware_version)
  end

  def over_user_device_limit?
    user.devices.count > user.device_limit
  end

  def error_prone_device?
    # Simple heuristic: device has been in error state multiple times
    # This would ideally check an audit log
    status == 'error' && updated_at != created_at
  end

  def calculate_estimated_downtime
    # Estimate downtime based on device patterns
    # This is a simplified calculation
    total_time = Time.current - created_at
    total_time * 0.05 # Assume 5% downtime on average
  end

  def calculate_diagnostic_score(issues)
    return 100 if issues.empty?
    
    penalty = issues.sum do |issue|
      case issue[:severity]
      when 'critical' then 30
      when 'medium' then 15
      when 'low' then 5
      else 0
      end
    end
    
    [100 - penalty, 0].max
  end

  def calculate_connection_reliability
    return 0 unless last_connection
    
    # Simplified reliability calculation
    age_days = (Time.current - created_at) / 1.day
    return 100 if age_days < 1
    
    # Assume devices should connect at least daily
    expected_connections = age_days
    # This would ideally check actual connection logs
    actual_reliability = last_connection > 1.day.ago ? 95 : 85
    actual_reliability
  end

  def calculate_average_session_duration
    # Placeholder - would calculate from connection logs
    "4.2 hours"
  end

  def calculate_data_quality_score
    return 0 unless respond_to?(:sensor_data)
    
    recent_data = sensor_data.where(created_at: 24.hours.ago..)
    return 0 if recent_data.empty?
    
    # Simple quality score based on data completeness
    expected_readings = 24 * 4 # Assume 15-minute intervals
    actual_readings = recent_data.count
    
    [(actual_readings.to_f / expected_readings * 100).round(1), 100].min
  end

  def calculate_error_frequency
    # Placeholder - would calculate from error logs
    status == 'error' ? 'High' : 'Low'
  end

  def calculate_maintenance_score
    score = 100
    score -= 20 if needs_firmware_update?
    score -= 30 if frequent_disconnects?
    score -= 40 if status == 'error'
    score -= 50 if never_connected?
    
    [score, 0].max
  end

  # ===== CLASS HELPER METHODS =====
  
  def self.latest_firmware_version
    # This would come from your firmware management system
    "1.2.3"
  end

  def self.calculate_fleet_utilization
    total_capacity = joins(:user).sum { |d| d.user.device_limit }
    return 0 if total_capacity == 0
    
    (count.to_f / total_capacity * 100).round(1)
  end

  def self.analyze_geographic_distribution
    # This would analyze device locations if tracked
    where.not(location: nil).group("location ->> 'country'").count
  end

  def self.calculate_average_device_age
    return 0 if count == 0
    
    total_age = sum { |device| Time.current - device.created_at }
    (total_age / count / 1.day).round(1)
  end

  def self.calculate_firmware_compliance
    total = count
    return 100 if total == 0
    
    up_to_date = where.not(firmware_version: nil).where(firmware_version: latest_firmware_version).count
    (up_to_date.to_f / total * 100).round(1)
  end

  def self.calculate_utilization_by_plan
    joins(user: { subscription: :plan })
      .group('plans.name')
      .group('plans.device_limit')
      .count
      .transform_keys { |plan_name, limit| "#{plan_name} (#{limit} devices)" }
  end
end