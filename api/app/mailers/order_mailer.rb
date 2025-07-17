# app/mailers/order_mailer.rb - EXTENDED
class OrderMailer < ApplicationMailer
  default from: 'orders@xspacegrow.com'

  def confirmation(order)
    @order = order
    @user = order.user
    @line_items = order.line_items.includes(:product)
    @device_items = @line_items.joins(:product).where.not(products: { device_type_id: nil })
    @total = order.total
    @order_number = order.id
    
    mail(
      to: @user.email,
      subject: "Order Confirmation ##{@order_number} - XSpaceGrow"
    )
  end

  def activation_instructions(activation_token)
    @activation_token = activation_token
    @order = activation_token.order
    @user = @order.user
    @device_type = activation_token.device_type
    @device_name = @device_type.name
    @token = activation_token.token
    @expires_at = activation_token.expires_at
    
    mail(
      to: @user.email,
      subject: "Device Activation Instructions - #{@device_name}"
    )
  end

  def payment_failed(order, failure_reason)
    @order = order
    @user = order.user
    @failure_reason = failure_reason
    @retry_url = "#{Rails.application.config.app_host}/shop/checkout?order_id=#{order.id}"
    
    mail(
      to: @user.email,
      subject: "Payment Failed - Order ##{order.id}"
    )
  end

  def refund_initiated(order, refund_amount)
    @order = order
    @user = order.user
    @refund_amount = refund_amount
    @refund_id = SecureRandom.hex(8).upcase
    
    mail(
      to: @user.email,
      subject: "Refund Initiated - Order ##{order.id}"
    )
  end

  # ✅ NEW: Retry reminder for failed payments
  def retry_reminder(order)
    @order = order
    @user = order.user
    @failure_reason = order.payment_failure_reason
    @retry_strategy = order.retry_strategy
    @retry_url = order.retry_payment_url
    @user_message = order.payment_failure_user_message
    @order_items = order.line_items.includes(:product)
    @device_count = order.device_count
    @total = order.total
    
    # Calculate time since failure
    @hours_since_failure = ((Time.current - order.payment_failed_at) / 1.hour).round if order.payment_failed_at
    
    # Generate helpful suggestions based on failure reason
    @suggestions = generate_retry_suggestions(@failure_reason)
    
    mail(
      to: @user.email,
      subject: "💳 Complete Your XSpaceGrow Order - Order ##{order.id}"
    )
  end

  # ✅ NEW: Setup help for device activation
  def setup_help(order)
    @order = order
    @user = order.user
    @device_tokens = order.device_activation_tokens.includes(:device_type)
    @device_count = order.device_count
    @total = order.total
    
    # Group tokens by device type for better organization
    @devices_by_type = @device_tokens.group_by(&:device_type)
    
    # Generate setup guides based on device types
    @setup_guides = generate_setup_guides(@devices_by_type.keys)
    
    # Calculate estimated setup time
    @estimated_setup_time = calculate_setup_time(@device_count)
    
    mail(
      to: @user.email,
      subject: "🚀 Get Started with Your XSpaceGrow Devices - Setup Guide"
    )
  end

  private

  def generate_retry_suggestions(failure_reason)
    case failure_reason&.downcase
    when /insufficient.funds/, /declined/
      [
        "Try a different payment method (credit/debit card)",
        "Contact your bank to ensure the transaction isn't blocked",
        "Check that your card has sufficient funds available"
      ]
    when /expired.card/, /invalid.expiry/
      [
        "Update your card expiration date",
        "Use a different, valid credit or debit card",
        "Contact your bank if you believe your card should be valid"
      ]
    when /incorrect.cvc/, /invalid.cvc/
      [
        "Double-check the 3-digit security code on the back of your card",
        "Ensure you're entering the CVC from the correct card",
        "Try using a different payment method"
      ]
    when /authentication.required/
      [
        "Complete the additional verification step (3D Secure)",
        "Check for text messages or app notifications from your bank",
        "Contact your bank if verification fails repeatedly"
      ]
    else
      [
        "Try again with the same payment method",
        "Use a different credit or debit card",
        "Contact our support team if the issue persists"
      ]
    end
  end

  def generate_setup_guides(device_types)
    guides = {}
    
    device_types.each do |device_type|
      case device_type.name
      when 'Environmental Monitor V1'
        guides[device_type] = {
          steps: [
            "Download the XSpaceGrow mobile app",
            "Power on your Environmental Monitor",
            "Follow the in-app pairing instructions",
            "Enter your activation token when prompted",
            "Place the device in your growing area",
            "Calibrate sensors using the app"
          ],
          estimated_time: "15-20 minutes",
          requirements: ["WiFi network", "Mobile device", "Power outlet"]
        }
      when 'Liquid Monitor V1'
        guides[device_type] = {
          steps: [
            "Download the XSpaceGrow mobile app",
            "Connect the probe to your Liquid Monitor",
            "Power on the device",
            "Follow the in-app setup wizard",
            "Enter your activation token",
            "Calibrate pH and EC sensors",
            "Install in your reservoir"
          ],
          estimated_time: "20-25 minutes",
          requirements: ["WiFi network", "Mobile device", "Calibration solutions", "Power outlet"]
        }
      else
        guides[device_type] = {
          steps: [
            "Download the XSpaceGrow mobile app",
            "Power on your device",
            "Follow the in-app setup instructions",
            "Enter your activation token when prompted"
          ],
          estimated_time: "10-15 minutes",
          requirements: ["WiFi network", "Mobile device", "Power outlet"]
        }
      end
    end
    
    guides
  end

  def calculate_setup_time(device_count)
    base_time = 15 # minutes for first device
    additional_time = (device_count - 1) * 10 # 10 minutes for each additional
    total_minutes = base_time + additional_time
    
    if total_minutes < 60
      "#{total_minutes} minutes"
    else
      hours = total_minutes / 60
      minutes = total_minutes % 60
      "#{hours} hour#{'s' if hours > 1}#{" #{minutes} minutes" if minutes > 0}"
    end
  end

  def app_host
    Rails.application.config.app_host || 'https://spacegrow.ai'
  end

  def dashboard_url
    "#{app_host}/dashboard"
  end

  def support_url
    "#{app_host}/support"
  end

  def app_download_url
    {
      ios: "https://apps.apple.com/app/spacegrow",
      android: "https://play.google.com/store/apps/details?id=com.spacegrow"
    }
  end
end