# app/jobs/accessory_follow_up_email_job.rb
class AccessoryFollowUpEmailJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    Rails.logger.info "🛠️ [AccessoryFollowUpEmailJob] Processing accessory follow-up email for order #{order.id}"

    # Only send if order is paid and has no devices (accessory-only order)
    unless order.paid? && !order.has_devices?
      Rails.logger.info "🛠️ [AccessoryFollowUpEmailJob] Order #{order.id} is not accessory-only, skipping"
      return
    end

    # Don't send if user already has devices or has made a device purchase since
    user = order.user
    if user.devices.any? || user.orders.joins(:products).where.not(products: { device_type_id: nil }).where('orders.created_at > ?', order.created_at).exists?
      Rails.logger.info "🛠️ [AccessoryFollowUpEmailJob] User #{user.id} already has devices or made device purchase, skipping"
      return
    end

    # Send accessory follow-up email with device recommendations
    result = EmailManagement::OrderEmailService.send_accessory_follow_up(order)
    
    if result[:success]
      Rails.logger.info "🛠️ [AccessoryFollowUpEmailJob] Accessory follow-up email sent successfully for order #{order.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        user,
        'accessory_follow_up_email_sent',
        {
          order_id: order.id,
          accessory_items: order.line_items.count,
          order_value: order.total,
          accessories_purchased: get_accessory_summary(order),
          recommended_devices: get_recommended_devices(order)
        }
      )

      # Schedule device promotion email if no action taken
      DevicePromotionEmailJob.set(wait: 5.days).perform_later(user.id, order.id)
    else
      Rails.logger.error "🛠️ [AccessoryFollowUpEmailJob] Failed to send accessory follow-up email for order #{order.id}: #{result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🛠️ [AccessoryFollowUpEmailJob] Order #{order_id} not found"
  rescue => e
    Rails.logger.error "🛠️ [AccessoryFollowUpEmailJob] Error processing accessory follow-up email for order #{order_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def get_accessory_summary(order)
    order.line_items.includes(:product).where(products: { device_type_id: nil }).map do |item|
      {
        name: item.product.name,
        quantity: item.quantity,
        category: determine_accessory_category(item.product)
      }
    end
  end

  def determine_accessory_category(product)
    name = product.name.downcase
    
    case name
    when /calibration/i
      'calibration'
    when /cleaning/i, /maintenance/i
      'maintenance'
    when /mounting/i, /bracket/i
      'mounting'
    when /sensor/i
      'sensor'
    else
      'general'
    end
  end

  def get_recommended_devices(order)
    # Recommend devices based on accessories purchased
    accessory_categories = order.line_items.includes(:product)
                               .where(products: { device_type_id: nil })
                               .map { |item| determine_accessory_category(item.product) }
    
    recommendations = []
    
    # If they bought calibration solutions, recommend liquid monitor
    if accessory_categories.include?('calibration')
      liquid_monitor = DeviceType.find_by(name: 'Liquid Monitor V1')
      recommendations << liquid_monitor.products.first if liquid_monitor
    end
    
    # If they bought mounting hardware, recommend environmental monitor
    if accessory_categories.include?('mounting')
      env_monitor = DeviceType.find_by(name: 'Environmental Monitor V1')
      recommendations << env_monitor.products.first if env_monitor
    end
    
    # Always include both if no specific recommendations
    if recommendations.empty?
      recommendations = Product.where.not(device_type_id: nil).featured.limit(2)
    end
    
    recommendations.compact.map do |product|
      {
        id: product.id,
        name: product.name,
        price: product.price,
        description: product.description
      }
    end
  end
end