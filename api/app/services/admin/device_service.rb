# app/services/admin/device_service.rb - SIMPLIFIED FOR STARTUP
module Admin
  class DeviceService < ApplicationService
    def fleet_overview
      begin
        success(
          summary: build_fleet_summary,
          recent_activity: get_recent_device_activity,
          problematic_devices: get_problematic_devices
        )
      rescue => e
        Rails.logger.error "Admin Device Fleet Overview error: #{e.message}"
        failure("Failed to load fleet overview: #{e.message}")
      end
    end

    def device_list(params = {})
      begin
        devices = build_devices_query(params)
        paginated_devices = devices.page(params[:page] || 1).per(25)
        
        success(
          devices: paginated_devices.map { |d| serialize_device(d) },
          total: devices.count,
          current_page: paginated_devices.current_page,
          total_pages: paginated_devices.total_pages
        )
      rescue => e
        Rails.logger.error "Admin Device List error: #{e.message}"
        failure("Failed to load devices: #{e.message}")
      end
    end

    def device_detail(device_id)
      begin
        device = Device.includes(:user, :device_type).find(device_id)
        
        success(
          device: serialize_device_detail(device),
          owner: serialize_device_owner(device.user),
          recent_activity: get_device_recent_activity(device)
        )
      rescue ActiveRecord::RecordNotFound
        failure("Device not found")
      rescue => e
        Rails.logger.error "Admin Device Detail error: #{e.message}"
        failure("Failed to load device details: #{e.message}")
      end
    end

    def suspend_device(device_id, reason)
      begin
        device = Device.find(device_id)
        
        if device.update(status: 'suspended')
          Rails.logger.info "Admin suspended device #{device.name}: #{reason}"
          
          success(
            message: "Device #{device.name} suspended successfully",
            device: serialize_device(device)
          )
        else
          failure("Failed to suspend device")
        end
      rescue ActiveRecord::RecordNotFound
        failure("Device not found")
      rescue => e
        Rails.logger.error "Admin Device Suspension error: #{e.message}"
        failure("Failed to suspend device: #{e.message}")
      end
    end

    def reactivate_device(device_id)
      begin
        device = Device.find(device_id)
        
        if device.update(status: 'active')
          Rails.logger.info "Admin reactivated device #{device.name}"
          
          success(
            message: "Device #{device.name} reactivated successfully",
            device: serialize_device(device)
          )
        else
          failure("Failed to reactivate device")
        end
      rescue ActiveRecord::RecordNotFound
        failure("Device not found")
      rescue => e
        Rails.logger.error "Admin Device Reactivation error: #{e.message}"
        failure("Failed to reactivate device: #{e.message}")
      end
    end

    private

    # === SIMPLE SUMMARY METHODS ===

    def build_fleet_summary
      {
        total_devices: Device.count,
        by_status: Device.group(:status).count,
        online_devices: Device.where(last_connection: 1.hour.ago..).count,
        offline_devices: Device.where(last_connection: ..1.hour.ago).or(Device.where(last_connection: nil)).count,
        error_devices: Device.where(status: 'error').count,
        new_this_week: Device.where(created_at: 1.week.ago..).count
      }
    end

    def get_recent_device_activity
      Device.includes(:user)
            .where(last_connection: 24.hours.ago..)
            .order(last_connection: :desc)
            .limit(5)
            .map { |d| serialize_device(d) }
    end

    def get_problematic_devices
      Device.includes(:user)
            .where("status = 'error' OR last_connection < ? OR last_connection IS NULL", 2.hours.ago)
            .order(:last_connection)
            .limit(5)
            .map { |d| serialize_device(d) }
    end

    # === QUERY BUILDING ===

    def build_devices_query(params)
      devices = Device.includes(:user, :device_type)
      
      # Filter by status
      if params[:status].present?
        case params[:status]
        when 'offline'
          devices = devices.where(last_connection: ..1.hour.ago).or(devices.where(last_connection: nil))
        when 'online'
          devices = devices.where(last_connection: 1.hour.ago..)
        else
          devices = devices.where(status: params[:status])
        end
      end
      
      # Filter by device type
      if params[:device_type].present?
        devices = devices.joins(:device_type).where(device_types: { id: params[:device_type] })
      end
      
      # Filter by user
      if params[:user_id].present?
        devices = devices.where(user_id: params[:user_id])
      end
      
      # Simple search
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        devices = devices.joins(:user).where(
          "devices.name ILIKE ? OR users.email ILIKE ? OR devices.id::text = ?",
          search_term, search_term, params[:search]
        )
      end
      
      devices.order(created_at: :desc)
    end

    # === SERIALIZATION METHODS ===

    def serialize_device(device)
      {
        id: device.id,
        name: device.name,
        status: device.status,
        device_type: device.device_type&.name,
        last_connection: device.last_connection&.iso8601,
        connection_status: determine_connection_status(device),
        owner_email: device.user.email,
        created_at: device.created_at.iso8601
      }
    end

    def serialize_device_detail(device)
      {
        id: device.id,
        name: device.name,
        status: device.status,
        device_type: device.device_type&.name,
        last_connection: device.last_connection&.iso8601,
        connection_status: determine_connection_status(device),
        created_at: device.created_at.iso8601,
        updated_at: device.updated_at.iso8601,
        activation_token: device.activation_token&.token,
        configuration: device.configuration
      }
    end

    def serialize_device_owner(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        subscription_plan: user.subscription&.plan&.name,
        device_count: user.devices.count,
        device_limit: user.device_limit
      }
    end

    def get_device_recent_activity(device)
      activities = []
      
      # Status changes
      if device.updated_at > 24.hours.ago
        activities << {
          type: 'status_change',
          description: "Status updated to #{device.status}",
          timestamp: device.updated_at
        }
      end
      
      # Connection activity
      if device.last_connection
        activities << {
          type: 'connection',
          description: "Last connected #{time_ago_in_words(device.last_connection)}",
          timestamp: device.last_connection
        }
      end
      
      activities.sort_by { |a| a[:timestamp] }.reverse.first(5)
    end

    # === HELPER METHODS ===

    def determine_connection_status(device)
      return 'never_connected' if device.last_connection.nil?
      return 'online' if device.last_connection > 10.minutes.ago
      return 'recently_offline' if device.last_connection > 1.hour.ago
      'offline'
    end

    def time_ago_in_words(time)
      return "Never" if time.nil?
      
      distance_in_minutes = ((Time.current - time) / 60).round
      
      case distance_in_minutes
      when 0..1 then "just now"
      when 2..59 then "#{distance_in_minutes} minutes ago"
      when 60..1439 then "#{distance_in_minutes / 60} hours ago"
      else "#{distance_in_minutes / 1440} days ago"
      end
    end
  end
end