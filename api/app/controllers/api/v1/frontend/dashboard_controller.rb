# app/controllers/api/v1/frontend/dashboard_controller.rb
class Api::V1::Frontend::DashboardController < Api::V1::Frontend::ProtectedController
  
  def index
    begin
      Rails.logger.info "Dashboard#index called for user: #{current_user.id}"
      
      # Get user with subscription info
      user_with_sub = current_user
      subscription = user_with_sub.subscription if user_with_sub.respond_to?(:subscription)
      
      # Get devices count
      devices_count = current_user.devices.count
      
      # Calculate device slots based on user role and subscription
      device_slots = calculate_device_slots(user_with_sub, subscription)
      
      # Get tier information
      tier_info = get_tier_info(user_with_sub, subscription)
      
      render json: {
        status: 'success',
        data: {
          userWithSub: serialize_user_with_subscription(user_with_sub, subscription),
          devices: devices_count,
          deviceSlots: device_slots,
          tierInfo: tier_info
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

  def serialize_user_with_subscription(user, subscription = nil)
    base_data = {
      id: user.id,
      email: user.email,
      role: user.role || 'user',
      device_limit: get_device_limit(user),
      available_device_slots: calculate_available_slots(user, subscription),
      created_at: user.created_at
    }
    
    if subscription
      base_data[:subscription] = {
        plan: {
          name: subscription.plan&.name || 'Basic',
          device_limit: subscription.plan&.device_limit || get_device_limit(user)
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

  def get_device_limit(user)
    case user.role&.to_s
    when 'admin'
      999 # Unlimited for admin
    when 'pro'
      10  # Pro users get 10 devices
    else
      2   # Free users get 2 devices
    end
  end

  def calculate_available_slots(user, subscription = nil)
    base_limit = get_device_limit(user)
    additional_slots = subscription&.additional_device_slots || 0
    total_limit = base_limit + additional_slots
    used_slots = current_user.devices.count
    
    [total_limit - used_slots, 0].max
  end

  def calculate_device_slots(user, subscription = nil)
    total_slots = 9 # 3x3 grid for UI
    base_limit = get_device_limit(user)
    additional_slots = subscription&.additional_device_slots || 0
    actual_device_limit = base_limit + additional_slots
    
    slots = []
    
    (1..total_slots).each do |position|
      if position <= actual_device_limit
        slots << {
          position: position,
          type: 'available',
          locked: false
        }
      else
        lock_reason = case user.role&.to_s
                     when 'user'
                       'Upgrade to Pro'
                     when 'pro'
                       'Add Extra Slot ($5/mo)'
                     else
                       'Add Extra Slot'
                     end
        
        slots << {
          position: position,
          type: 'locked',
          locked: true,
          lock_reason: lock_reason
        }
      end
    end
    
    slots
  end

  def get_tier_info(user, subscription = nil)
    base_limit = get_device_limit(user)
    additional_slots = subscription&.additional_device_slots || 0
    
    {
      planName: subscription&.plan&.name || (user.role&.capitalize || 'Basic'),
      baseLimit: base_limit,
      additionalSlots: additional_slots,
      totalLimit: base_limit + additional_slots,
      usedSlots: current_user.devices.count
    }
  end
end