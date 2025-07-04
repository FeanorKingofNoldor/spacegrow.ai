# app/services/device_management_service.rb
class DeviceManagementService
  class << self
    def disable_devices(device_ids, reason: 'plan_change')
      return [] if device_ids.empty?

      devices = Device.where(id: device_ids)
      disabled_devices = []

      Device.transaction do
        devices.each do |device|
          # Use the new model method if available, fallback to basic update
          if device.respond_to?(:disable_with_reason!)
            device.disable_with_reason!(reason)
          else
            # Fallback for backwards compatibility
            update_attributes = { status: 'disabled' }
            
            # Only set these if the columns exist
            if device.respond_to?(:disabled_reason)
              update_attributes.merge!(
                disabled_reason: reason,
                disabled_at: Time.current,
                previous_status: device.status
              )
            end
            
            device.update!(update_attributes)
          end
          
          # Expire activation tokens
          device.activation_token&.update!(expires_at: Time.current)
          
          disabled_devices << {
            id: device.id,
            name: device.name,
            previous_status: device.respond_to?(:previous_status) ? device.previous_status : device.status
          }
        end
      end

      # Log the action
      Rails.logger.info "Disabled #{disabled_devices.count} devices: #{disabled_devices.map { |d| d[:name] }.join(', ')}"
      
      disabled_devices
    end

    # ✅ NEW: Enable devices (for upgrade scenarios or reactivation)
    def enable_devices(device_ids)
      return [] if device_ids.empty?

      devices = Device.where(id: device_ids, status: 'disabled')
      enabled_devices = []

      Device.transaction do
        devices.each do |device|
          # Restore previous status or default to pending
          new_status = device.previous_status || 'pending'
          
          device.update!(
            status: new_status,
            disabled_reason: nil,
            disabled_at: nil,
            previous_status: nil
          )
          
          enabled_devices << {
            id: device.id,
            name: device.name,
            new_status: new_status
          }
        end
      end

      # Log the action
      Rails.logger.info "Enabled #{enabled_devices.count} devices: #{enabled_devices.map { |d| d[:name] }.join(', ')}"
      
      enabled_devices
    end

    # ✅ NEW: Get devices suitable for selection during downgrade
    def get_devices_for_selection(user)
      user.devices.active
          .includes(:device_type, :device_sensors)
          .left_joins(:device_sensors)
          .select('devices.*, CASE 
                     WHEN devices.last_connection IS NULL OR devices.last_connection < ? THEN 0
                     WHEN devices.last_connection < ? THEN 1  
                     ELSE 2
                   END as connection_priority', 1.week.ago, 1.day.ago)
          .order('connection_priority ASC, devices.last_connection ASC NULLS FIRST, devices.created_at ASC')
          .map { |device| format_device_for_selection(device) }
    end

    # ✅ NEW: Check if devices can be safely disabled
    def can_disable_devices?(device_ids)
      devices = Device.where(id: device_ids)
      
      # Check if any devices have critical processes running
      critical_devices = devices.select do |device|
        has_active_commands?(device) || has_critical_sensors?(device)
      end

      {
        can_disable: critical_devices.empty?,
        critical_devices: critical_devices.map { |d| { id: d.id, name: d.name, reason: get_critical_reason(d) } },
        warnings: generate_disable_warnings(devices)
      }
    end

    # ✅ NEW: Schedule device changes for end of period
    def schedule_device_changes(user, device_ids_to_disable, effective_date)
      scheduled_change = ScheduledDeviceChange.create!(
        user: user,
        device_ids: device_ids_to_disable,
        action: 'disable',
        scheduled_for: effective_date,
        reason: 'plan_change',
        status: 'pending'
      )

      # Schedule background job
      ScheduledDeviceChangeJob.set(wait_until: effective_date)
                             .perform_later(scheduled_change.id)

      {
        scheduled_change_id: scheduled_change.id,
        effective_date: effective_date,
        device_count: device_ids_to_disable.length
      }
    end

    # ✅ NEW: Get device status summary for user
    def get_device_summary(user)
      devices = user.devices.includes(:device_type)
      
      {
        total: devices.count,
        active: devices.active.count,
        pending: devices.pending.count,
        disabled: devices.disabled.count,
        offline: devices.active.where('last_connection < ? OR last_connection IS NULL', 1.day.ago).count,
        with_errors: devices.active.where(alert_status: 'error').count,
        with_warnings: devices.active.where(alert_status: 'warning').count,
        device_limit: user.subscription&.device_limit || user.device_limit,
        available_slots: calculate_available_slots(user)
      }
    end

    private

    # Format device data for selection UI
    def format_device_for_selection(device)
      {
        id: device.id,
        name: device.name,
        device_type: device.device_type.name,
        status: device.status,
        alert_status: device.alert_status || 'unknown',
        last_connection: device.last_connection,
        is_offline: device_offline?(device),
        offline_duration: calculate_offline_duration(device),
        sensor_count: device.device_sensors.count,
        has_errors: device.alert_status == 'error',
        priority_score: device.try(:connection_priority) || 0,
        recommendation: get_selection_recommendation(device)
      }
    end

    # Check if device is offline
    def device_offline?(device)
      device.last_connection.nil? || device.last_connection < 1.day.ago
    end

    # Calculate how long device has been offline
    def calculate_offline_duration(device)
      return nil unless device_offline?(device)
      return 'Never connected' if device.last_connection.nil?
      
      duration = Time.current - device.last_connection
      
      if duration > 1.week
        "#{(duration / 1.week).floor} week#{'s' if duration > 2.weeks} ago"
      elsif duration > 1.day
        "#{(duration / 1.day).floor} day#{'s' if duration > 2.days} ago"
      else
        "#{(duration / 1.hour).floor} hour#{'s' if duration > 2.hours} ago"
      end
    end

    # Get recommendation for device selection
    def get_selection_recommendation(device)
      return 'recommended_to_disable' if device_offline?(device) && device.last_connection && device.last_connection < 1.week.ago
      return 'consider_disabling' if device_offline?(device)
      return 'has_errors' if device.alert_status == 'error'
      return 'keep_active' # Default recommendation
    end

    # Check if device has active commands
    def has_active_commands?(device)
      device.command_logs.where(status: ['pending', 'executing']).exists?
    end

    # Check if device has critical sensors
    def has_critical_sensors?(device)
      device.device_sensors.joins(:sensor_type)
            .where(sensor_types: { is_critical: true })
            .where('last_reading_at > ?', 1.hour.ago)
            .exists?
    end

    # Get reason why device is critical
    def get_critical_reason(device)
      return 'Active commands running' if has_active_commands?(device)
      return 'Critical sensors active' if has_critical_sensors?(device)
      'Unknown'
    end

    # Generate warnings for disabling devices
    def generate_disable_warnings(devices)
      warnings = []
      
      recently_active = devices.select { |d| d.last_connection&.> 1.hour.ago }
      if recently_active.any?
        warnings << "#{recently_active.count} device#{'s' if recently_active.count > 1} recently active"
      end

      with_errors = devices.select { |d| d.alert_status == 'error' }
      if with_errors.any?
        warnings << "#{with_errors.count} device#{'s' if with_errors.count > 1} currently have errors"
      end

      warnings
    end

    # Calculate available device slots for user
    def calculate_available_slots(user)
      if user.subscription
        limit = user.subscription.device_limit
        used = user.devices.active.count
        [limit - used, 0].max
      else
        [user.device_limit - user.devices.count, 0].max
      end
    end
  end
end