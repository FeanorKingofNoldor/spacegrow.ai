# app/mailers/order_mailer.rb
class OrderMailer < ApplicationMailer
  default from: 'orders@spacegrow.local'

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

  private

  def app_host
    Rails.application.config.app_host || 'http://localhost:3000'
  end
end