# app/services/admin/device_fleet_service.rb
module Admin
  class DeviceFleetService < ApplicationService
    def fleet_overview(params)
      begin
        devices = Device.includes(:user, :device_type, :device_sensors)
        
        # Apply filters
        devices = apply_device_filters(devices, params)
        
        # Apply sorting
        devices = apply_device_sorting(devices, params[:sort_by], params[:sort_direction])
        
        # Pagination
        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 25, 100].min
        
        paginated_devices = devices.page(page).per(per_page)
        
        success(
          devices: serialize_devices_list(paginated_devices),
          pagination: {
            current_page: page,
            per_page: per_page,
            total_pages: paginated_devices.total_pages,
            total_count: paginated_devices.total_count
          },
          fleet_summary: build_fleet_summary(devices),
          health_overview: build_health_overview(devices),
          filters: build_device_filter_options
        )
      rescue => e
        Rails.logger.error "Device fleet overview error: #{e.message}"
        failure("Failed to load device fleet: #{e.message}")
      end
    end

    def device_detailed_view(device)
      begin
        success(
          device: serialize_device_detail(device),
          owner_info: serialize_device_owner(device.user),
          health_metrics: calculate_device_health_metrics(device),
          recent_activity: build_device_recent_activity(device),
          sensor_data_summary: build_sensor_data_summary(device),
          connection_history: build_connection_history(device),
          troubleshooting_info: build_device_troubleshooting(device),
          available_actions: determine_device_admin_actions(device)
        )
      rescue => e
        Rails.logger.error "Device detail view error: #{e.message}"
        failure("Failed to load device details: #{e.message}")
      end
    end

    def fleet_health_analysis(period = 'week')
      begin
        date_range = calculate_date_range(period)
        
        # Use only real data from Device model
        all_devices = Device.includes(:user)
        recent_devices = all_devices.where(last_connection: date_range)
        
        analysis = {
          connection_health: analyze_real_connection_health(all_devices, date_range),
          device_lifecycle: analyze_real_device_lifecycle(date_range),
          fleet_status: build_real_fleet_status(all_devices)
        }
        
        success(
          period: period,
          date_range: date_range,
          analysis: analysis,
          recommendations: generate_real_recommendations(analysis)
        )
      rescue => e
        Rails.logger.error "Fleet health analysis error: #{e.message}"
        failure("Failed to analyze fleet health: #{e.message}")
      end
    end

    def admin_update_device_status(device, new_status, reason = nil)
      begin
        return failure("Invalid status") unless valid_device_status?(new_status)
        return failure("Device is already #{new_status}") if device.status == new_status
        
        old_status = device.status
        ActiveRecord::Base.transaction do
          # Use existing DeviceStateManager for consistency
          case new_status
          when 'active'
            result = reactivate_device_admin(device)
            return result unless result[:success]
          when 'suspended'
            result = suspend_device_admin(device, reason)
            return result unless result[:success]
          when 'disabled'
            device.update!(status: 'disabled')
          else
            device.update!(status: new_status)
          end
          
          # Log admin action
          log_device_admin_action(device, 'status_change', {
            old_status: old_status,
            new_status: new_status,
            reason: reason
          })
          
          # Send notification to user if configured
          if should_notify_status_change?(old_status, new_status)
            send_device_status_notification(device, old_status, new_status, reason)
          end
        end
        
        success(
          message: "Device status updated from #{old_status} to #{new_status}",
          device: serialize_device_detail(device.reload),
          status_change: {
            old_status: old_status,
            new_status: new_status,
            changed_at: Time.current,
            reason: reason
          }
        )
      rescue => e
        Rails.logger.error "Device status update error: #{e.message}"
        failure("Failed to update device status: #{e.message}")
      end
    end

    def bulk_device_operations(operation, device_ids, params)
      begin
        devices = Device.where(id: device_ids)
        return failure("No valid devices found") if devices.empty?
        
        case operation
        when 'update_status'
          result = bulk_status_update(devices, params[:status], params[:reason])
        when 'assign_type'
          result = bulk_assign_device_type(devices, params[:device_type_id])
        when 'export_data'
          result = bulk_export_device_data(devices, params[:format])
        else
          return failure("Unknown operation: #{operation}")
        end
        
        if result[:success]
          success(
            message: result[:message],
            affected_count: result[:affected_count],
            operation: operation,
            summary: result[:summary]
          )
        else
          failure(result[:error])
        end
      rescue => e
        Rails.logger.error "Bulk device operation error: #{e.message}"
        failure("Failed to perform bulk operation: #{e.message}")
      end
    end

    def device_troubleshooting_info(device)
      begin
        success(
          device_id: device.id,
          current_status: device.status,
          last_connection: device.last_connection,
          diagnostics: generate_device_diagnostics(device),
          troubleshooting_steps: generate_troubleshooting_steps(device),
          suggested_fixes: generate_suggested_fixes(device),
          contact_support: build_support_contact_info(device)
        )
      rescue => e
        Rails.logger.error "Device troubleshooting error: #{e.message}"
        failure("Failed to load troubleshooting info: #{e.message}")
      end
    end

    private

    # ===== FILTER AND SORT METHODS =====
    
    def apply_device_filters(devices, params)
      devices = devices.where(status: params[:status]) if params[:status].present?
      devices = devices.where(device_type_id: params[:device_type_id]) if params[:device_type_id].present?
      devices = devices.joins(:user).where(users: { role: params[:user_role] }) if params[:user_role].present?
      
      if params[:last_connection].present?
        case params[:last_connection]
        when 'online'
          devices = devices.where(last_connection: 5.minutes.ago..Time.current)
        when 'recent'
          devices = devices.where(last_connection: 1.hour.ago..Time.current)
        when 'offline'
          devices = devices.where(last_connection: ..1.hour.ago)
        end
      end
      
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        devices = devices.joins(:user).where(
          "devices.device_id ILIKE ? OR users.email ILIKE ?", 
          search_term, search_term
        )
      end
      
      devices
    end

    def apply_device_sorting(devices, sort_by, direction)
      direction = %w[asc desc].include?(direction) ? direction : 'desc'
      
      case sort_by
      when 'last_connection'
        devices.order(last_connection: direction)
      when 'created_at'
        devices.order(created_at: direction)
      when 'status'
        devices.order(status: direction)
      when 'user_email'
        devices.joins(:user).order("users.email #{direction}")
      else
        devices.order(created_at: :desc)
      end
    end

    # ===== SERIALIZATION METHODS =====
    
    def serialize_devices_list(devices)
      devices.map do |device|
        {
          id: device.id,
          device_id: device.device_id,
          status: device.status,
          device_type: device.device_type&.name,
          user_email: device.user.email,
          user_role: device.user.role,
          last_connection: device.last_connection&.iso8601,
          created_at: device.created_at.iso8601,
          sensor_count: device.device_sensors.count,
          is_online: device.last_connection && device.last_connection > 5.minutes.ago
        }
      end
    end

    def serialize_device_detail(device)
      {
        id: device.id,
        device_id: device.device_id,
        status: device.status,
        device_type: device.device_type&.name,
        activation_token: device.activation_token,
        last_connection: device.last_connection&.iso8601,
        created_at: device.created_at.iso8601,
        updated_at: device.updated_at.iso8601,
        sensor_types: device.device_sensors.includes(:sensor_type).map do |ds|
          {
            sensor_type: ds.sensor_type.name,
            unit: ds.sensor_type.unit,
            is_active: ds.is_active
          }
        end
      }
    end

    def serialize_device_owner(user)
      {
        id: user.id,
        email: user.email,
        role: user.role,
        created_at: user.created_at.iso8601,
        device_count: user.devices.count,
        subscription_status: user.subscription&.status
      }
    end

    # ===== REAL DATA ANALYSIS METHODS =====
    
    def build_fleet_summary(devices)
      total_devices = devices.count
      online_devices = devices.where(last_connection: 5.minutes.ago..Time.current).count
      
      {
        total_devices: total_devices,
        online_devices: online_devices,
        offline_devices: total_devices - online_devices,
        status_breakdown: devices.group(:status).count,
        device_type_breakdown: devices.joins(:device_type).group('device_types.name').count
      }
    end

    def build_health_overview(devices)
      {
        online_percentage: devices.count > 0 ? (devices.where(last_connection: 5.minutes.ago..Time.current).count.to_f / devices.count * 100).round(1) : 0,
        recent_connections: devices.where(last_connection: 1.hour.ago..Time.current).count,
        never_connected: devices.where(last_connection: nil).count,
        error_devices: devices.where(status: 'error').count
      }
    end

    def build_device_filter_options
      {
        statuses: Device.distinct.pluck(:status).compact,
        device_types: DeviceType.pluck(:id, :name),
        user_roles: User.distinct.pluck(:role).compact
      }
    end

    def calculate_device_health_metrics(device)
      recent_data_count = device.device_sensors.joins(:sensor_data)
                               .where(sensor_data: { created_at: 24.hours.ago..Time.current })
                               .count
      
      {
        is_online: device.last_connection && device.last_connection > 5.minutes.ago,
        last_connection: device.last_connection&.iso8601,
        connection_status: determine_connection_status(device),
        recent_data_points: recent_data_count,
        sensor_count: device.device_sensors.count,
        active_sensors: device.device_sensors.where(is_active: true).count
      }
    end

    def build_device_recent_activity(device)
      # Get recent sensor data
      recent_data = SensorData.joins(device_sensor: :device)
                             .where(devices: { id: device.id })
                             .order(created_at: :desc)
                             .limit(10)
                             .includes(device_sensor: :sensor_type)

      recent_data.map do |data|
        {
          timestamp: data.created_at.iso8601,
          sensor_type: data.device_sensor.sensor_type.name,
          value: data.value,
          unit: data.device_sensor.sensor_type.unit
        }
      end
    end

    def build_sensor_data_summary(device)
      device.device_sensors.includes(:sensor_type).map do |device_sensor|
        latest_data = device_sensor.sensor_data.order(created_at: :desc).first
        
        {
          sensor_type: device_sensor.sensor_type.name,
          unit: device_sensor.sensor_type.unit,
          is_active: device_sensor.is_active,
          latest_value: latest_data&.value,
          latest_timestamp: latest_data&.created_at&.iso8601,
          data_count_24h: device_sensor.sensor_data.where(created_at: 24.hours.ago..Time.current).count
        }
      end
    end

    def build_connection_history(device)
      # This would require connection logging - simplified version
      {
        last_connection: device.last_connection&.iso8601,
        total_connections_estimate: device.device_sensors.joins(:sensor_data).count,
        first_connection: device.created_at.iso8601
      }
    end

    def analyze_real_connection_health(devices, date_range)
      total_devices = devices.count
      connected_devices = devices.where(last_connection: date_range).count
      never_connected = devices.where(last_connection: nil).count
      
      {
        total_devices: total_devices,
        connected_in_period: connected_devices,
        never_connected: never_connected,
        connection_rate: total_devices > 0 ? (connected_devices.to_f / total_devices * 100).round(1) : 0
      }
    end

    def analyze_real_device_lifecycle(date_range)
      {
        new_devices: Device.where(created_at: date_range).count,
        disabled_devices: Device.where(updated_at: date_range, status: 'disabled').count,
        reactivated_devices: Device.where(updated_at: date_range, status: 'active').count
      }
    end

    def build_real_fleet_status(devices)
      {
        status_distribution: devices.group(:status).count,
        role_distribution: devices.joins(:user).group('users.role').count,
        device_type_distribution: devices.joins(:device_type).group('device_types.name').count
      }
    end

    def generate_real_recommendations(analysis)
      recommendations = []
      
      connection_health = analysis[:connection_health]
      if connection_health[:never_connected] > 0
        recommendations << "#{connection_health[:never_connected]} devices have never connected - check activation process"
      end
      
      if connection_health[:connection_rate] < 80
        recommendations << "Low connection rate (#{connection_health[:connection_rate]}%) - investigate connectivity issues"
      end
      
      recommendations
    end

    # ===== DEVICE OPERATIONS =====
    
    def reactivate_device_admin(device)
      # Check if user has available device slots
      user = device.user
      if user.devices.where(status: 'active').count >= user.device_limit
        return failure("User has reached device limit")
      end
      
      device.update!(status: 'active')
      success(message: "Device reactivated successfully")
    end

    def suspend_device_admin(device, reason)
      device.update!(status: 'suspended')
      success(message: "Device suspended: #{reason}")
    end

    def bulk_status_update(devices, new_status, reason)
      return failure("Invalid status") unless valid_device_status?(new_status)
      
      updated_count = 0
      devices.each do |device|
        if device.status != new_status
          device.update!(status: new_status)
          log_device_admin_action(device, 'bulk_status_change', { 
            new_status: new_status, 
            reason: reason 
          })
          updated_count += 1
        end
      end
      
      success(
        message: "Updated #{updated_count} devices to #{new_status}",
        affected_count: updated_count,
        summary: { status: new_status, reason: reason }
      )
    end

    def bulk_assign_device_type(devices, device_type_id)
      device_type = DeviceType.find_by(id: device_type_id)
      return failure("Invalid device type") unless device_type
      
      updated_count = devices.update_all(device_type_id: device_type_id)
      
      success(
        message: "Assigned #{updated_count} devices to #{device_type.name}",
        affected_count: updated_count,
        summary: { device_type: device_type.name }
      )
    end

    def bulk_export_device_data(devices, format)
      # This would generate export file - simplified
      success(
        message: "Export initiated for #{devices.count} devices",
        affected_count: devices.count,
        summary: { format: format, device_count: devices.count }
      )
    end

    # ===== TROUBLESHOOTING METHODS =====
    
    def build_device_troubleshooting(device)
      {
        diagnostics: generate_device_diagnostics(device),
        common_issues: generate_common_issues_for_device(device),
        troubleshooting_steps: generate_troubleshooting_steps(device)
      }
    end

    def generate_device_diagnostics(device)
      {
        device_id: device.device_id,
        status: device.status,
        last_seen: device.last_connection&.iso8601,
        minutes_since_last_connection: device.last_connection ? ((Time.current - device.last_connection) / 1.minute).round : nil,
        sensor_count: device.device_sensors.count,
        recent_data_points: device.device_sensors.joins(:sensor_data)
                                 .where(sensor_data: { created_at: 1.hour.ago..Time.current })
                                 .count
      }
    end

    def generate_common_issues_for_device(device)
      issues = []
      
      if device.last_connection.nil?
        issues << "Device has never connected - check activation token"
      elsif device.last_connection < 1.hour.ago
        issues << "Device appears offline - check power and network connection"
      end
      
      if device.device_sensors.where(is_active: true).count == 0
        issues << "No active sensors configured"
      end
      
      issues
    end

    def generate_troubleshooting_steps(device)
      steps = ['Verify device power status']
      
      if device.last_connection.nil?
        steps += [
          'Check device power connection',
          'Verify network connectivity',
          'Confirm activation token is valid'
        ]
      elsif device.last_connection < 1.hour.ago
        steps += [
          'Check device network connection',
          'Verify device is within range of WiFi',
          'Restart device if accessible'
        ]
      end
      
      steps
    end

    def generate_suggested_fixes(device)
      fixes = []
      
      case device.status
      when 'error'
        fixes << 'Reset device to factory settings'
        fixes << 'Check error logs for specific issues'
      when 'suspended'
        fixes << 'Reactivate device if user has available slots'
      when 'pending'
        fixes << 'Complete device activation process'
      end
      
      fixes
    end

    def build_support_contact_info(device)
      {
        device_id: device.device_id,
        support_reference: "DEV-#{device.id}",
        user_email: device.user.email
      }
    end

    # ===== HELPER METHODS =====
    
    def determine_device_admin_actions(device)
      actions = ['view_details', 'view_logs']
      
      case device.status
      when 'active'
        actions += ['suspend_device', 'view_sensor_data']
      when 'suspended'
        actions += ['reactivate_device']
      when 'error'
        actions += ['reset_device', 'view_diagnostics']
      when 'pending'
        actions += ['complete_activation']
      end
      
      actions << 'download_logs' if device.device_sensors.joins(:sensor_data).exists?
      actions
    end

    def determine_connection_status(device)
      return 'never_connected' if device.last_connection.nil?
      return 'online' if device.last_connection > 5.minutes.ago
      return 'recently_online' if device.last_connection > 1.hour.ago
      'offline'
    end

    def valid_device_status?(status)
      %w[active suspended disabled error pending].include?(status)
    end

    def calculate_date_range(period)
      case period
      when 'day' then 1.day.ago..Time.current
      when 'week' then 1.week.ago..Time.current
      when 'month' then 1.month.ago..Time.current
      when 'quarter' then 3.months.ago..Time.current
      else 1.week.ago..Time.current
      end
    end

    def log_device_admin_action(device, action, metadata = {})
      Rails.logger.info "Admin Device Action: #{action} on device #{device.id} - #{metadata}"
      # TODO: Store in admin audit log table if needed
    end

    def should_notify_status_change?(old_status, new_status)
      # Only notify for significant status changes
      significant_changes = [
        ['active', 'suspended'],
        ['suspended', 'active'],
        ['active', 'disabled'],
        ['error', 'active']
      ]
      
      significant_changes.include?([old_status, new_status])
    end

    def send_device_status_notification(device, old_status, new_status, reason)
      # Send notification via email or push notification
      Rails.logger.info "Sending device status notification: #{device.device_id} #{old_status} -> #{new_status}"
      
      # TODO: Implement actual notification sending
      # NotificationService.send_device_status_change(device, old_status, new_status, reason)
    end
  end
end