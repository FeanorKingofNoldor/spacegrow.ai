# app/controllers/api/v1/frontend/dashboard_controller.rb
class Api::V1::Frontend::DashboardController < Api::V1::Frontend::ProtectedController
  
  def index
    begin
      Rails.logger.info "Dashboard#index called for user: #{current_user.id}"
      
      render json: {
        status: 'success',
        data: {
          userWithSub: serialize_user_with_subscription,
          devices: current_user.devices.count,
          deviceSlots: calculate_device_slots_for_ui,
          tierInfo: build_tier_info
        }
      }
    rescue => e
      Rails.logger.error "Dashboard error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: {
        status: 'error',
        error: 'Failed to load dashboard data',
        message: e.message
      }, status: 500
    end
  end

  def devices
    begin
      devices = current_user.devices.includes(:device_type)
      
      render json: {
        status: 'success',
        data: devices.map { |device| serialize_device(device) },
        message: "Found #{devices.count} devices"
      }
    rescue => e
      Rails.logger.error "Dashboard devices error: #{e.message}"
      
      render json: {
        status: 'error',
        error: 'Failed to load devices',
        message: e.message
      }, status: 500
    end
  end

  def device
    begin
      device = current_user.devices.find(params[:id])
      
      render json: {
        status: 'success',
        data: serialize_device_detail(device)
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: 'error',
        error: 'Device not found'
      }, status: 404
    rescue => e
      Rails.logger.error "Dashboard device error: #{e.message}"
      
      render json: {
        status: 'error',
        error: 'Failed to load device',
        message: e.message
      }, status: 500
    end
  end

  private

  # ✅ CLEANED: Use model methods instead of duplicating logic
  def serialize_user_with_subscription
    subscription = current_user.subscription
    
    base_data = {
      id: current_user.id,
      email: current_user.email,
      role: current_user.role || 'user',
      device_limit: current_user.device_limit,                    # ✅ From User model (correct!)
      available_device_slots: current_user.available_device_slots, # ✅ From User model (correct!)
      created_at: current_user.created_at
    }
    
    if subscription
      base_data[:subscription] = {
        plan: {
          name: subscription.plan&.name || 'Basic',
          device_limit: subscription.plan&.device_limit || current_user.device_limit
        },
        additional_device_slots: subscription.additional_device_slots || 0,
        status: subscription.status || 'active'
      }
    end
    
    base_data
  end

  def serialize_device(device)
    {
      id: device.id,
      name: device.name,
      status: device.status,
      alert_status: device.alert_status || 'normal',
      device_type: device.device_type&.name || device.device_type_id&.to_s || 'Unknown',
      last_connection: device.last_connection,
      created_at: device.created_at,
      updated_at: device.updated_at
    }
  end

  def serialize_device_detail(device)
    base = serialize_device(device)
    base.merge({
      commands_count: device.respond_to?(:commands) ? device.commands.count : 0,
      recent_sensor_data: device.respond_to?(:sensor_data) ? device.sensor_data.limit(10).order(created_at: :desc) : []
    })
  end

  # ✅ SIMPLIFIED: Only handles UI grid layout, uses model methods for limits
  def calculate_device_slots_for_ui
    total_slots = 9 # 3x3 grid for UI
    device_limit = current_user.device_limit  # ✅ From User model (handles subscription + role)
    
    slots = []
    
    (1..total_slots).each do |position|
      if position <= device_limit
        slots << {
          position: position,
          type: 'available',
          locked: false
        }
      else
        slots << {
          position: position,
          type: 'locked',
          locked: true,
          lock_reason: get_lock_reason_for_ui
        }
      end
    end
    
    slots
  end

  # ✅ SIMPLIFIED: Uses model data for tier info
  def build_tier_info
    subscription = current_user.subscription
    
    # Use model methods for accurate data
    base_limit = subscription&.plan&.device_limit || fallback_device_limit
    additional_slots = subscription&.additional_device_slots || 0
    
    {
      planName: subscription&.plan&.name || (current_user.role&.capitalize || 'Basic'),
      baseLimit: base_limit,
      additionalSlots: additional_slots,
      totalLimit: current_user.device_limit,        # ✅ From User model (already calculated correctly)
      usedSlots: current_user.devices.count
    }
  end

  # ✅ HELPER: UI-specific logic only
  def get_lock_reason_for_ui
    case current_user.role&.to_s
    when 'user'
      'Upgrade to Pro'
    when 'pro'
      'Add Extra Slot ($5/mo)'
    when 'enterprise'
      'Contact Support'
    else
      'Add Extra Slot'
    end
  end

  # ✅ HELPER: Fallback for users without subscription (matches User model logic)
  def fallback_device_limit
    case current_user.role&.to_s
    when 'admin'
      999
    when 'pro'
      4  # ✅ CORRECT VALUE (was 10 in duplicate method)
    when 'enterprise'
      999
    else
      2
    end
  end
end