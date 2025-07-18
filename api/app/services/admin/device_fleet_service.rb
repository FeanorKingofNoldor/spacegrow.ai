# app/services/admin/device_fleet_service.rb
module Admin
  class DeviceFleetService < ApplicationService
    def fleet_overview(params)
      begin
        devices = Device.includes(:user, :device_type)
        
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
        
        analysis = {
          connection_health: analyze_connection_health(date_range),
          performance_metrics: analyze_performance_metrics(date_range),
          error_patterns: analyze_error_patterns(date_range),
          geographic_distribution: analyze_geographic_distribution,
          device_lifecycle: analyze_device_lifecycle(date_range),
          alerts_summary: build_fleet_alerts_summary
        }
        
        success(
          period: period,
          date_range: date_range,
          analysis: analysis,
          recommendations: generate_fleet_recommendations(analysis)
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
            reason: reason,
            changed_by: current_admin_id
          })
          
          # Send notification to user if needed
          send_device_status_notification(device, old_status, new_status, reason)
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
        
        results = []
        failed_operations = []
        
        devices.find_each do |device|
          case operation
          when 'update_status'
            result = admin_update_device_status(device, params[:new_status], params[:reason])
          when 'force_reconnect'
            result = force_device_reconnect(device)
          when 'send_notification'
            result = send_device_notification(device, params[:notification_message])
          else
            failed_operations << { device_id: device.id, error: "Unknown operation: #{operation}" }
            next
          end
          
          if result[:success]
            results << { device_id: device.id, status: 'success' }
          else
            failed_operations << { device_id: device.id, error: result[:error] }
          end
        end
        
        success(
          message: "Bulk operation completed",
          operation: operation,
          successful_operations: results.count,
          failed_operations: failed_operations.count,
          results: results,
          failures: failed_operations
        )
      rescue => e
        Rails.logger.error "Bulk device operation error: #{e.message}"
        failure("Failed to perform bulk operation: #{e.message}")
      end
    end

    def device_troubleshooting_info(device)
      begin
        troubleshooting = {
          connectivity: analyze_connectivity_issues(device),
          performance: analyze_performance_issues(device),
          configuration: analyze_configuration_issues(device),
          recent_errors: fetch_recent_device_errors(device),
          diagnostic_steps: generate_diagnostic_steps(device),
          suggested_fixes: generate_suggested_fixes(device)
        }
        
        success(
          device_id: device.id,
          troubleshooting: troubleshooting,
          last_analyzed: Time.current
        )
      rescue => e
        Rails.logger.error "Device troubleshooting error: #{e.message}"
        failure("Failed to generate troubleshooting info: #{e.message}")
      end
    end

    def device_analytics(period = 'month')
      begin
        date_range = calculate_date_range(period)
        
        analytics = {
          fleet_growth: calculate_fleet_growth(date_range),
          activation_rates: calculate_activation_rates(date_range),
          usage_patterns: analyze_usage_patterns(date_range),
          reliability_metrics: calculate_reliability_metrics(date_range),
          user_engagement: analyze_user_engagement(date_range)
        }
        
        success(
          period: period,
          date_range: date_range,
          analytics: analytics,
          trends: identify_device_trends(analytics)
        )
      rescue => e
        Rails.logger.error "Device analytics error: #{e.message}"
        failure("Failed to generate device analytics: #{e.message}")
      end
    end

    def force_device_reconnect(device)
      begin
        # This would integrate with your device communication system
        # For now, simulate the reconnection attempt
        
        log_device_admin_action(device, 'force_reconnect', {
          initiated_by: current_admin_id,
          initiated_at: Time.current
        })
        
        # Update device to indicate reconnection was attempted
        device.update!(last_reconnect_attempt: Time.current)
        
        success(
          message: "Reconnection command sent to device",
          device: serialize_device_detail(device),
          reconnect_details: {
            attempted_at: Time.current,
            expected_reconnect_time: 2.minutes.from_now
          }
        )
      rescue => e
        Rails.logger.error "Force reconnect error: #{e.message}"
        failure("Failed to force device reconnection: #{e.message}")
      end
    end

    private

    # ===== FILTER AND SORTING METHODS =====
    
    def apply_device_filters(devices, params)
      devices = devices.where(status: params[:status]) if params[:status].present?
      devices = devices.where(user_id: params[:user_id]) if params[:user_id].present?
      devices = devices.where(device_type_id: params[:device_type_id]) if params[:device_type_id].present?
      devices = devices.where(last_connection: ..params[:last_connection_before]) if params[:last_connection_before].present?
      devices = devices.where(last_connection: params[:last_connection_after]..) if params[:last_connection_after].present?
      devices = devices.where(created_at: params[:created_after]..) if params[:created_after].present?
      devices = devices.where(created_at: ..params[:created_before]) if params[:created_before].present?
      
      if params[:search].present?
        devices = devices.joins(:user).where(
          "devices.name ILIKE ? OR devices.id::text = ? OR users.email ILIKE ?",
          "%#{params[:search]}%", params[:search], "%#{params[:search]}%"
        )
      end
      
      devices
    end

    def apply_device_sorting(devices, sort_by, direction)
      direction = direction&.downcase == 'desc' ? :desc : :asc
      
      case sort_by
      when 'name'
        devices.order(name: direction)
      when 'created_at'
        devices.order(created_at: direction)
      when 'last_connection'
        devices.order(last_connection: direction)
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
          name: device.name,
          status: device.status,
          device_type: device.device_type&.name,
          user_email: device.user.email,
          last_connection: device.last_connection,
          created_at: device.created_at,
          health_status: determine_device_health_status(device),
          alert_level: determine_device_alert_level(device)
        }
      end
    end

    def serialize_device_detail(device)
      {
        id: device.id,
        name: device.name,
        status: device.status,
        device_type: device.device_type&.name,
        created_at: device.created_at,
        updated_at: device.updated_at,
        last_connection: device.last_connection,
        last_reconnect_attempt: device.last_reconnect_attempt,
        activation_token: device.activation_token&.token,
        firmware_version: device.firmware_version,
        hardware_info: device.hardware_info,
        configuration: device.configuration,
        location: device.location
      }
    end

    def serialize_device_owner(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        role: user.role,
        subscription_plan: user.subscription&.plan&.name,
        device_count: user.devices.count,
        device_limit: user.device_limit
      }
    end

    # ===== ANALYSIS METHODS =====
    
    def build_fleet_summary(devices_scope)
      {
        total_devices: devices_scope.count,
        by_status: devices_scope.group(:status).count,
        by_type: devices_scope.joins(:device_type).group('device_types.name').count,
        online_devices: devices_scope.where(last_connection: 1.hour.ago..).count,
        offline_devices: devices_scope.where(last_connection: ..1.hour.ago).count,
        never_connected: devices_scope.where(last_connection: nil).count
      }
    end

    def build_health_overview(devices_scope)
      {
        healthy_devices: devices_scope.where(last_connection: 10.minutes.ago..).count,
        warning_devices: devices_scope.where(last_connection: 10.minutes.ago..1.hour.ago).count,
        critical_devices: devices_scope.where(last_connection: ..1.hour.ago).count,
        avg_uptime: calculate_average_uptime(devices_scope),
        connection_success_rate: calculate_connection_success_rate(devices_scope)
      }
    end

    def build_device_filter_options
      {
        statuses: Device.distinct.pluck(:status).compact,
        device_types: DeviceType.pluck(:id, :name).map { |id, name| { id: id, name: name } }
      }
    end

    def calculate_device_health_metrics(device)
      {
        uptime_percentage: calculate_device_uptime(device),
        connection_reliability: calculate_connection_reliability(device),
        data_quality_score: calculate_data_quality_score(device),
        performance_score: calculate_performance_score(device),
        last_health_check: Time.current
      }
    end

    def build_device_recent_activity(device, limit = 10)
      activities = []
      
      # Connection events
      if device.last_connection
        activities << {
          type: 'connection',
          description: 'Last connected',
          timestamp: device.last_connection,
          metadata: { connection_type: 'normal' }
        }
      end
      
      # Status changes
      # This would come from your audit log system
      activities << {
        type: 'status_change',
        description: "Status: #{device.status}",
        timestamp: device.updated_at,
        metadata: { status: device.status }
      }
      
      # Recent sensor data
      if device.respond_to?(:sensor_data)
        device.sensor_data.recent.limit(3).each do |data|
          activities << {
            type: 'sensor_data',
            description: "Sensor reading: #{data.sensor_type}",
            timestamp: data.created_at,
            metadata: { sensor_type: data.sensor_type, value: data.value }
          }
        end
      end
      
      activities.sort_by { |a| a[:timestamp] }.reverse.first(limit)
    end

    def build_sensor_data_summary(device)
      return {} unless device.respond_to?(:sensor_data)
      
      recent_data = device.sensor_data.where(created_at: 24.hours.ago..)
      
      {
        total_readings_24h: recent_data.count,
        sensor_types: recent_data.group(:sensor_type).count,
        data_quality: calculate_sensor_data_quality(recent_data),
        latest_reading: recent_data.order(created_at: :desc).first
      }
    end

    def build_connection_history(device, limit = 20)
      # This would come from your connection logging system
      # For now, return sample data
      [
        {
          timestamp: device.last_connection || 1.hour.ago,
          status: 'connected',
          duration: '45 minutes',
          signal_strength: -67
        },
        {
          timestamp: 2.hours.ago,
          status: 'disconnected',
          duration: '30 seconds',
          reason: 'network_timeout'
        }
      ]
    end

    def build_device_troubleshooting(device)
      issues = []
      
      if device.last_connection.nil?
        issues << { type: 'never_connected', severity: 'high', description: 'Device has never connected' }
      elsif device.last_connection < 1.hour.ago
        issues << { type: 'offline', severity: 'medium', description: 'Device has been offline for over an hour' }
      end
      
      if device.status == 'error'
        issues << { type: 'error_status', severity: 'high', description: 'Device is in error state' }
      end
      
      issues
    end

    def determine_device_admin_actions(device)
      actions = []
      
      actions << 'update_status'
      actions << 'force_reconnect' if device.last_connection && device.last_connection < 10.minutes.ago
      actions << 'send_notification'
      actions << 'view_sensor_data' if device.respond_to?(:sensor_data)
      actions << 'download_logs'
      actions << 'reset_device' if device.status == 'error'
      
      actions
    end

    # ===== HEALTH ANALYSIS METHODS =====
    
    def analyze_connection_health(date_range)
      {
        connection_events: Device.where(last_connection: date_range).count,
        average_uptime: calculate_fleet_average_uptime(date_range),
        connection_failures: count_connection_failures(date_range),
        reconnection_rate: calculate_reconnection_rate(date_range)
      }
    end

    def analyze_performance_metrics(date_range)
      {
        data_throughput: calculate_data_throughput(date_range),
        response_times: calculate_average_response_times(date_range),
        error_rates: calculate_error_rates(date_range),
        resource_utilization: calculate_resource_utilization(date_range)
      }
    end

    def analyze_error_patterns(date_range)
      # This would analyze device error logs
      {
        total_errors: 0, # Placeholder
        error_types: {},
        error_trends: {},
        affected_devices: 0
      }
    end

    def analyze_geographic_distribution
      # This would analyze device locations if you track them
      {
        by_region: {},
        by_timezone: {},
        coverage_areas: []
      }
    end

    def analyze_device_lifecycle(date_range)
      {
        new_activations: Device.where(created_at: date_range).count,
        deactivations: Device.where(updated_at: date_range, status: 'disabled').count,
        avg_device_age: calculate_average_device_age,
        lifecycle_stage_distribution: calculate_lifecycle_distribution
      }
    end

    def build_fleet_alerts_summary
      {
        critical_alerts: Device.where(last_connection: ..1.hour.ago).count,
        warning_alerts: Device.where(last_connection: 10.minutes.ago..1.hour.ago).count,
        maintenance_due: 0, # Placeholder
        security_alerts: 0 # Placeholder
      }
    end

    # ===== DEVICE OPERATION METHODS =====
    
    def reactivate_device_admin(device)
      # Use existing DeviceStateManager for consistency
      state_manager = Billing::DeviceStateManager.new(device.user)
      result = state_manager.activate_device(device)
      
      if result[:success]
        success(message: "Device reactivated successfully")
      else
        failure(result[:error])
      end
    end

    def suspend_device_admin(device, reason)
      # Use existing DeviceStateManager for consistency
      state_manager = Billing::DeviceStateManager.new(device.user)
      result = state_manager.suspend_device(device, reason: "admin_suspension: #{reason}")
      
      if result[:success]
        success(message: "Device suspended successfully")
      else
        failure(result[:error])
      end
    end

    def send_device_notification(device, message)
      # This would integrate with your device communication system
      Rails.logger.info "Sending notification to device #{device.id}: #{message}"
      success(message: "Notification sent successfully")
    end

    # ===== CALCULATION HELPERS =====
    
    def determine_device_health_status(device)
      return 'critical' if device.last_connection.nil? || device.last_connection < 1.hour.ago
      return 'warning' if device.last_connection < 10.minutes.ago
      'healthy'
    end

    def determine_device_alert_level(device)
      return 'high' if device.status == 'error' || device.last_connection.nil?
      return 'medium' if device.last_connection && device.last_connection < 30.minutes.ago
      'low'
    end

    def calculate_device_uptime(device)
      # Calculate uptime percentage over last 30 days
      # This would integrate with your monitoring system
      95.5 # Placeholder
    end

    def calculate_connection_reliability(device)
      # Calculate connection success rate
      # This would analyze connection attempts vs successes
      98.2 # Placeholder
    end

    def calculate_data_quality_score(device)
      # Analyze data consistency, completeness, accuracy
      87.3 # Placeholder
    end

    def calculate_performance_score(device)
      # Overall performance score based on multiple metrics
      92.1 # Placeholder
    end

    def calculate_average_uptime(devices_scope)
      # Calculate average uptime across all devices
      94.7 # Placeholder
    end

    def calculate_connection_success_rate(devices_scope)
      # Calculate overall connection success rate
      96.8 # Placeholder
    end

    def calculate_sensor_data_quality(sensor_data)
      return 0 if sensor_data.empty?
      
      # Analyze data completeness, consistency, etc.
      total_expected = 24 * 60 / 5 # Assuming 5-minute intervals
      actual_readings = sensor_data.count
      
      (actual_readings.to_f / total_expected * 100).round(1)
    end

    # ===== ANALYTICS HELPERS =====
    
    def calculate_fleet_growth(date_range)
      {
        new_devices: Device.where(created_at: date_range).count,
        activated_devices: Device.where(created_at: date_range, status: 'active').count,
        growth_rate: calculate_growth_rate(date_range)
      }
    end

    def calculate_activation_rates(date_range)
      new_devices = Device.where(created_at: date_range).count
      activated_devices = Device.where(created_at: date_range, status: 'active').count
      
      {
        total_new: new_devices,
        activated: activated_devices,
        activation_rate: new_devices > 0 ? ((activated_devices.to_f / new_devices) * 100).round(1) : 0
      }
    end

    def analyze_usage_patterns(date_range)
      # Analyze how devices are being used
      {
        most_active_hours: analyze_peak_usage_hours(date_range),
        usage_frequency: calculate_usage_frequency(date_range),
        feature_adoption: analyze_feature_adoption(date_range)
      }
    end

    def calculate_reliability_metrics(date_range)
      {
        average_uptime: calculate_fleet_average_uptime(date_range),
        mtbf: calculate_mean_time_between_failures(date_range),
        mttr: calculate_mean_time_to_repair(date_range)
      }
    end

    def analyze_user_engagement(date_range)
      {
        active_users: Device.joins(:user).where(last_connection: date_range).distinct.count(:user_id),
        device_interactions: count_device_interactions(date_range),
        engagement_score: calculate_engagement_score(date_range)
      }
    end

    # ===== TROUBLESHOOTING HELPERS =====
    
    def analyze_connectivity_issues(device)
      issues = []
      
      if device.last_connection.nil?
        issues << { type: 'never_connected', description: 'Device has never established connection' }
      elsif device.last_connection < 1.hour.ago
        issues << { type: 'connection_timeout', description: 'Device connection timeout detected' }
      end
      
      issues
    end

    def analyze_performance_issues(device)
      # Analyze device performance issues
      []
    end

    def analyze_configuration_issues(device)
      # Analyze device configuration problems
      []
    end

    def fetch_recent_device_errors(device)
      # Fetch recent error logs for the device
      []
    end

    def generate_diagnostic_steps(device)
      steps = []
      
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
        fixes << 'Update device firmware'
      when 'suspended'
        fixes << 'Reactivate device if user has available slots'
      end
      
      fixes
    end

    def generate_fleet_recommendations(analysis)
      recommendations = []
      
      if analysis[:connection_health][:connection_failures] > 10
        recommendations << "High connection failure rate detected - review network infrastructure"
      end
      
      if analysis[:alerts_summary][:critical_alerts] > 5
        recommendations << "Multiple devices offline - investigate potential service issues"
      end
      
      recommendations
    end

    def identify_device_trends(analytics)
      trends = []
      
      if analytics[:fleet_growth][:growth_rate] > 20
        trends << { type: 'positive', description: 'Rapid fleet growth detected' }
      end
      
      if analytics[:reliability_metrics][:average_uptime] < 95
        trends << { type: 'negative', description: 'Fleet reliability below target' }
      end
      
      trends
    end

    # ===== HELPER METHODS =====
    
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
    end

    def send_device_status_notification(device, old_status, new_status, reason)
      # Send notification to device owner about status change
      Rails.logger.info "Sending device status notification: #{device.id} #{old_status} -> #{new_status}"
    end

    def current_admin_id
      1 # Placeholder - implement based on your auth system
    end

    # Placeholder implementations for complex calculations
    def calculate_fleet_average_uptime(date_range); 94.5; end
    def count_connection_failures(date_range); 5; end
    def calculate_reconnection_rate(date_range); 87.3; end
    def calculate_data_throughput(date_range); "1.2 MB/hour"; end
    def calculate_average_response_times(date_range); "150ms"; end
    def calculate_error_rates(date_range); 2.1; end
    def calculate_resource_utilization(date_range); 68.4; end
    def calculate_average_device_age; 245.days; end
    def calculate_lifecycle_distribution; {}; end
    def calculate_growth_rate(date_range); 15.2; end
    def analyze_peak_usage_hours(date_range); [9, 14, 18]; end
    def calculate_usage_frequency(date_range); "Every 4.2 hours"; end
    def analyze_feature_adoption(date_range); {}; end
    def calculate_mean_time_between_failures(date_range); "720 hours"; end
    def calculate_mean_time_to_repair(date_range); "2.5 hours"; end
    def count_device_interactions(date_range); 1245; end
    def calculate_engagement_score(date_range); 78.3; end
  end
end