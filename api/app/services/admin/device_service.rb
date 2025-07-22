# app/services/admin/device_service.rb
module Admin
  class DeviceService < ApplicationService
    def fleet_overview
      begin
        success(
          summary: build_fleet_summary,
          health_metrics: build_health_metrics,
          recent_activity: get_recent_device_activity,
          problematic_devices: get_problematic_devices,
          top_users_by_devices: get_top_users_by_devices
        )
      rescue => e
        Rails.logger.error "Admin Device Fleet Overview error: #{e.message}"
        failure("Failed to load fleet overview: #{e.message}")
      end
    end

    def device_list(params = {})
      begin
        devices = build_devices_query(params)
        
        success(
          devices: devices.page(params[:page]).per(25).map { |d| serialize_device(d) },
          total: devices.count,
          filters: build_device_filters,
          summary: build_devices_summary(devices)
        )
      rescue => e
        Rails.logger.error "Admin Device List error: #{e.message}"
        failure("Failed to load devices: #{e.message}")
      end
    end

    def device_detail(device_id)
      begin
        device = Device.includes(:user, :device_type, :sensor_data).find(device_id)
        
        success(
          device: serialize_device_detail(device),
          connection_history: build_connection_history(device),
          recent_sensor_data: get_recent_sensor_data(device),
          troubleshooting: build_troubleshooting_info(device),
          quick_actions: build_device_actions(device)
        )
      rescue ActiveRecord::RecordNotFound
        failure("Device not found")
      rescue => e
        Rails.logger.error "Admin Device Detail error: #{e.message}"
        failure("Failed to load device details: #{e.message}")
      end
    end

    def restart_device(device_id)
      begin
        device = Device.find(device_id)
        
        # Send restart command to device via your ESP32 API
        # This would integrate with your existing device communication system
        restart_result = send_restart_command(device)
        
        if restart_result[:success]
          # Log the restart command
          Rails.logger.info "Admin sent restart command to device #{device.name} (#{device.id})"
          
          # Track the action
          track_device_action('restart', device.id)
          
          success(
            message: "Restart command sent to #{device.name}",
            command_id: restart_result[:command_id],
            estimated_completion: 30.seconds.from_now
          )
        else
          failure("Failed to send restart command: #{restart_result[:error]}")
        end
      rescue ActiveRecord::RecordNotFound
        failure("Device not found")
      rescue => e
        Rails.logger.error "Admin Device Restart error: #{e.message}"
        failure("Failed to restart device: #{e.message}")
      end
    end

    def bulk_suspend_devices(device_ids, reason)
      begin
        devices = Device.where(id: device_ids)
        suspended_count = 0
        
        ActiveRecord::Base.transaction do
          devices.each do |device|
            if device.update(status: 'suspended')
              suspended_count += 1
              Rails.logger.info "Admin suspended device #{device.name}: #{reason}"
            end
          end
        end
        
        success(
          message: "Successfully suspended #{suspended_count} devices",
          suspended_count: suspended_count
        )
      rescue => e
        Rails.logger.error "Admin Bulk Device Suspension error: #{e.message}"
        failure("Failed to suspend devices: #{e.message}")
      end
    end

    def device_troubleshooting(device_id)
      begin
        device = Device.includes(:user, :device_type).find(device_id)
        
        troubleshooting = {
          device_info: serialize_device_detail(device),
          connectivity_check: check_device_connectivity(device),
          recent_errors: get_device_errors(device),
          configuration_status: check_device_configuration(device),
          recommended_actions: generate_troubleshooting_recommendations(device)
        }
        
        success(troubleshooting)
      rescue ActiveRecord::RecordNotFound
        failure("Device not found")
      rescue => e
        Rails.logger.error "Admin Device Troubleshooting error: #{e.message}"
        failure("Failed to load troubleshooting info: #{e.message}")
      end
    end

    private

    def build_fleet_summary
      {
        total_devices: Device.count,
        by_status: Device.group(:status).count,
        by_device_type: Device.joins(:device_type).group('device_types.name').count,
        online_last_hour: Device.where(last_connection: 1.hour.ago..).count,
        never_connected: Device.where(last_connection: nil).count,
        new_this_week: Device.where(created_at: 1.week.ago..).count
      }
    end

    def build_health_metrics
      total = Device.count
      return {} if total == 0
      
      online = Device.where(status: 'active').count
      offline = Device.where(last_connection: ..1.hour.ago).count
      errors = Device.where(status: 'error').count
      
      {
        connectivity_rate: ((online.to_f / total) * 100).round(1),
        error_rate: ((errors.to_f / total) * 100).round(1),
        offline_rate: ((offline.to_f / total) * 100).round(1),
        health_score: calculate_fleet_health_score(online, offline, errors, total)
      }
    end

    def get_recent_device_activity
      Device.includes(:user, :device_type)
            .where(last_connection: 24.hours.ago..)
            .order(last_connection: :desc)
            .limit(10)
            .map { |d| serialize_device(d) }
    end

    def get_problematic_devices
      Device.includes(:user, :device_type)
            .where("status = ? OR last_connection < ?", 'error', 1.hour.ago)
            .order(:last_connection)
            .limit(10)
            .map { |d| serialize_device(d) }
    end

    def get_top_users_by_devices
      User.joins(:devices)
          .group('users.id, users.email')
          .having('COUNT(devices.id) > 5')
          .order('COUNT(devices.id) DESC')
          .limit(10)
          .pluck('users.email, COUNT(devices.id)')
          .map { |email, count| { email: email, device_count: count } }
    end

    def build_devices_query(params)
      devices = Device.includes(:user, :device_type)
      
      # Filter by status
      if params[:status].present?
        case params[:status]
        when 'offline'
          devices = devices.where(last_connection: ..1.hour.ago)
        else
          devices = devices.where(status: params[:status])
        end
      end
      
      # Filter by device type
      if params[:device_type].present?
        devices = devices.joins(:device_type).where(device_types: { name: params[:device_type] })
      end
      
      # Filter by user
      if params[:user_id].present?
        devices = devices.where(user_id: params[:user_id])
      end
      
      # Search by name or user email
      if params[:search].present?
        devices = devices.joins(:user).where(
          "devices.name ILIKE ? OR users.email ILIKE ?",
          "%#{params[:search]}%", "%#{params[:search]}%"
        )
      end
      
      devices.order(:created_at)
    end

    def serialize_device(device)
      {
        id: device.id,
        name: device.name,
        device_type: device.device_type&.name,
        status: device.status,
        user_email: device.user.email,
        last_connection: device.last_connection,
        created_at: device.created_at,
        connection_status: determine_connection_status(device),
        sensor_count: device.device_sensors.count
      }
    end

    def serialize_device_detail(device)
      {
        id: device.id,
        name: device.name,
        device_type: device.device_type&.name,
        status: device.status,
        user: {
          id: device.user.id,
          email: device.user.email,
          display_name: device.user.display_name
        },
        last_connection: device.last_connection,
        created_at: device.created_at,
        updated_at: device.updated_at,
        api_token: device.api_token&.slice(0, 8) + "...", # Partial token for security
        connection_info: {
          total_connections: calculate_total_connections(device),
          avg_connection_duration: calculate_avg_connection_duration(device),
          uptime_percentage: calculate_device_uptime(device)
        }
      }
    end

    def build_connection_history(device)
      # This would pull from your device connection logs if you have them
      # For now, simplified based on last_connection
      [
        {
          timestamp: device.last_connection || device.created_at,
          event: device.last_connection ? 'connected' : 'registered',
          duration: device.last_connection ? "Connected" : "Never connected"
        }
      ]
    end

    def get_recent_sensor_data(device)
      device.sensor_data
            .includes(:device_sensor)
            .order(created_at: :desc)
            .limit(20)
            .map do |data|
              {
                sensor_type: data.device_sensor&.sensor_type&.name,
                value: data.value,
                unit: data.device_sensor&.sensor_type&.unit,
                timestamp: data.created_at
              }
            end
    end

    def build_troubleshooting_info(device)
      {
        last_seen: time_ago_in_words(device.last_connection || device.created_at),
        connection_issues: detect_connection_issues(device),
        configuration_problems: detect_configuration_problems(device),
        recent_errors: get_device_error_logs(device),
        network_status: check_device_network_status(device)
      }
    end

    def build_device_actions(device)
      actions = []
      
      if device.status == 'active'
        actions << { action: 'restart', label: 'Restart Device', type: 'warning' }
        actions << { action: 'suspend', label: 'Suspend Device', type: 'danger' }
      elsif device.status == 'suspended'
        actions << { action: 'reactivate', label: 'Reactivate Device', type: 'success' }
      elsif device.status == 'error'
        actions << { action: 'restart', label: 'Restart Device', type: 'warning' }
        actions << { action: 'troubleshoot', label: 'Run Diagnostics', type: 'info' }
      end
      
      actions << { action: 'view_logs', label: 'View Logs', type: 'info' }
      actions << { action: 'edit_config', label: 'Edit Configuration', type: 'info' }
      
      actions
    end

    def build_device_filters
      {
        statuses: Device.distinct.pluck(:status).compact,
        device_types: DeviceType.pluck(:name),
        connection_states: ['online', 'offline', 'never_connected']
      }
    end

    def build_devices_summary(devices_scope)
      {
        total_devices: devices_scope.count,
        by_status: devices_scope.group(:status).count,
        by_device_type: devices_scope.joins(:device_type).group('device_types.name').count
      }
    end

    # === HELPER METHODS ===

    def determine_connection_status(device)
      return 'never_connected' if device.last_connection.nil?
      return 'online' if device.last_connection > 10.minutes.ago
      return 'recently_offline' if device.last_connection > 1.hour.ago
      'offline'
    end

    def calculate_fleet_health_score(online, offline, errors, total)
      return 100 if total == 0
      
      # Simple health scoring: online devices = good, errors = very bad
      health_score = ((online - (errors * 2)).to_f / total * 100).round(1)
      [health_score, 0].max # Don't go below 0
    end

    def send_restart_command(device)
      # This would integrate with your ESP32 device communication API
      # For now, return a mock success response
      {
        success: true,
        command_id: SecureRandom.hex(8),
        message: "Restart command queued"
      }
    rescue => e
      {
        success: false,
        error: e.message
      }
    end

    def track_device_action(action, device_id)
      Rails.logger.info "Admin Device Action: #{action} for device #{device_id}"
      
      # Track in Prometheus if available
      if defined?(Yabeda)
        Yabeda.spacegrow.device_connections.increment(
          tags: { status: action, device_type: 'admin_action' }
        )
      end
    rescue => e
      Rails.logger.debug "Device action tracking failed: #{e.message}"
    end

    # Placeholder methods for device monitoring features
    def calculate_total_connections(device); 0; end
    def calculate_avg_connection_duration(device); "Unknown"; end  
    def calculate_device_uptime(device); 95.0; end
    def detect_connection_issues(device); []; end
    def detect_configuration_problems(device); []; end
    def get_device_error_logs(device); []; end
    def check_device_network_status(device); "Unknown"; end
    def check_device_connectivity(device); { status: 'unknown' }; end
    def get_device_errors(device); []; end
    def check_device_configuration(device); { status: 'unknown' }; end
    def generate_troubleshooting_recommendations(device); ["Check device connection", "Verify configuration"]; end
    
    def time_ago_in_words(time)
      return "Never" if time.nil?
      distance_in_minutes = ((Time.current - time) / 60).round
      
      case distance_in_minutes
      when 0..1 then "Just now"
      when 2..59 then "#{distance_in_minutes} minutes ago"
      when 60..1439 then "#{distance_in_minutes / 60} hours ago"
      else "#{distance_in_minutes / 1440} days ago"
      end
    end
  end
end