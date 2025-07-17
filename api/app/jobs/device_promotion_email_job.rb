# app/jobs/device_promotion_email_job.rb
class DevicePromotionEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, original_order_id)
    user = User.find_by(id: user_id)
    return unless user

    original_order = Order.find_by(id: original_order_id)
    return unless original_order

    Rails.logger.info "📱 [DevicePromotionEmailJob] Processing device promotion for user #{user.id}"

    # Only send if user still has no devices
    if user.devices.any?
      Rails.logger.info "📱 [DevicePromotionEmailJob] User #{user.id} now has devices, skipping promotion"
      return
    end

    # Don't send if user has made any device purchases since original order
    if user.orders.joins(:products)
           .where.not(products: { device_type_id: nil })
           .where('orders.created_at > ?', original_order.created_at)
           .exists?
      Rails.logger.info "📱 [DevicePromotionEmailJob] User #{user.id} has made device purchases since, skipping"
      return
    end

    # Send device promotion email
    result = EmailManagement::OrderEmailService.send_device_promotion(user, original_order)
    
    if result[:success]
      Rails.logger.info "📱 [DevicePromotionEmailJob] Device promotion email sent successfully for user #{user.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        user,
        'device_promotion_email_sent',
        {
          original_order_id: original_order.id,
          days_since_accessory_purchase: (Time.current - original_order.created_at) / 1.day,
          accessories_purchased: original_order.line_items.count,
          promotion_type: determine_promotion_type(original_order),
          recommended_devices: get_promotion_devices(original_order)
        }
      )

      # Schedule final follow-up if no action taken
      FinalDeviceFollowUpJob.set(wait: 7.days).perform_later(user.id, original_order.id)
    else
      Rails.logger.error "📱 [DevicePromotionEmailJob] Failed to send device promotion for user #{user.id}: #{result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "📱 [DevicePromotionEmailJob] User #{user_id} or Order #{original_order_id} not found"
  rescue => e
    Rails.logger.error "📱 [DevicePromotionEmailJob] Error processing device promotion for user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def determine_promotion_type(order)
    accessory_names = order.line_items.includes(:product).pluck('products.name').join(' ').downcase
    
    case accessory_names
    when /calibration/i
      'liquid_monitor_focused'
    when /mounting/i
      'environmental_monitor_focused'
    when /cleaning/i, /maintenance/i
      'maintenance_focused'
    else
      'general_device_promotion'
    end
  end

  def get_promotion_devices(order)
    # Get recommended devices based on accessories purchased
    promotion_type = determine_promotion_type(order)
    
    case promotion_type
    when 'liquid_monitor_focused'
      [
        Product.joins(:device_type).find_by(device_types: { name: 'Liquid Monitor V1' }),
        Product.joins(:device_type).find_by(device_types: { name: 'Environmental Monitor V1' })
      ]
    when 'environmental_monitor_focused'
      [
        Product.joins(:device_type).find_by(device_types: { name: 'Environmental Monitor V1' }),
        Product.joins(:device_type).find_by(device_types: { name: 'Liquid Monitor V1' })
      ]
    else
      Product.joins(:device_type).featured.limit(2)
    end.compact.map do |product|
      {
        id: product.id,
        name: product.name,
        price: product.price,
        description: product.description,
        features: extract_device_features(product),
        discount_available: calculate_discount_for_user(order.user, product)
      }
    end
  end

  def extract_device_features(product)
    return [] unless product.device_type
    
    # Extract features from device type configuration
    sensor_types = product.device_type.configuration.dig('supported_sensor_types')&.keys || []
    actuators = product.device_type.configuration.dig('supported_actuators')&.keys || []
    
    features = sensor_types.map { |sensor| "#{sensor} monitoring" }
    features += actuators.map { |actuator| "#{actuator.humanize} control" }
    
    features.first(4) # Limit to top 4 features
  end

  def calculate_discount_for_user(user, product)
    # Simple discount logic based on user behavior
    base_discount = 0
    
    # First-time device buyer discount
    base_discount += 10 if user.orders.joins(:products).where.not(products: { device_type_id: nil }).empty?
    
    # Accessory purchaser discount
    base_discount += 5 if user.orders.joins(:products).where(products: { device_type_id: nil }).any?
    
    # Time-based discount (longer wait = bigger discount)
    first_order_age = (Time.current - user.orders.first.created_at) / 1.day
    if first_order_age > 14
      base_discount += 5
    elsif first_order_age > 7
      base_discount += 3
    end
    
    # Cap discount at 20%
    [base_discount, 20].min
  end
end