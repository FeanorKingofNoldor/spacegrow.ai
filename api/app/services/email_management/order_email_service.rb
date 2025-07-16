# app/services/email_management/order_email_service.rb
module EmailManagement
  class OrderEmailService < ApplicationService
    def self.send_confirmation(order)
      new(order).send_confirmation
    end

    def self.send_activation_instructions(order)
      new(order).send_activation_instructions
    end

    def self.send_payment_failed(order, failure_reason)
      new(order).send_payment_failed(failure_reason)
    end

    def self.send_refund_notification(order, refund_amount)
      new(order).send_refund_notification(refund_amount)
    end

    def initialize(order)
      @order = order
      @user = order.user
    end

    def send_confirmation
      return failure('Order must be paid to send confirmation') unless @order.paid?
      return failure('User email not found') unless @user.email.present?

      begin
        Rails.logger.info "📧 [OrderEmailService] Sending confirmation email for order #{@order.id}"
        
        OrderMailer.confirmation(@order).deliver_now
        @order.mark_confirmation_email_sent!
        
        success(
          message: "Order confirmation email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'order_confirmation'
        )
      rescue => e
        Rails.logger.error "📧 [OrderEmailService] Failed to send confirmation email for order #{@order.id}: #{e.message}"
        failure("Failed to send confirmation email: #{e.message}")
      end
    end

    def send_activation_instructions
      return failure('Order must be paid to send activation instructions') unless @order.paid?
      return failure('User email not found') unless @user.email.present?

      device_tokens = @order.device_activation_tokens.includes(:device_type)
      return success(message: 'No device activation tokens found') if device_tokens.empty?

      begin
        Rails.logger.info "📧 [OrderEmailService] Sending #{device_tokens.count} activation instruction emails for order #{@order.id}"
        
        sent_count = 0
        device_tokens.each do |token|
          OrderMailer.activation_instructions(token).deliver_now
          sent_count += 1
          Rails.logger.info "📧 [OrderEmailService] Sent activation instructions for #{token.device_type.name} (token: #{token.token[0..7]}...)"
        end

        @order.mark_activation_emails_sent!(sent_count)
        
        success(
          message: "#{sent_count} activation instruction email(s) sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'device_activation',
          tokens_sent: sent_count
        )
      rescue => e
        Rails.logger.error "📧 [OrderEmailService] Failed to send activation instructions for order #{@order.id}: #{e.message}"
        failure("Failed to send activation instructions: #{e.message}")
      end
    end

    def send_payment_failed(failure_reason)
      return failure('User email not found') unless @user.email.present?

      begin
        Rails.logger.info "📧 [OrderEmailService] Sending payment failure email for order #{@order.id}"
        
        OrderMailer.payment_failed(@order, failure_reason).deliver_now
        @order.mark_payment_failure_email_sent!
        
        success(
          message: "Payment failure email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'payment_failed',
          failure_reason: failure_reason
        )
      rescue => e
        Rails.logger.error "📧 [OrderEmailService] Failed to send payment failure email for order #{@order.id}: #{e.message}"
        failure("Failed to send payment failure email: #{e.message}")
      end
    end

    def send_refund_notification(refund_amount)
      return failure('User email not found') unless @user.email.present?

      begin
        Rails.logger.info "📧 [OrderEmailService] Sending refund notification for order #{@order.id}"
        
        OrderMailer.refund_initiated(@order, refund_amount).deliver_now
        
        success(
          message: "Refund notification email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'refund_notification',
          refund_amount: refund_amount
        )
      rescue => e
        Rails.logger.error "📧 [OrderEmailService] Failed to send refund notification for order #{@order.id}: #{e.message}"
        failure("Failed to send refund notification: #{e.message}")
      end
    end

    # Batch operation: Send all order-related emails
    def send_complete_order_flow
      return failure('Order must be paid') unless @order.paid?

      results = []
      
      # Send order confirmation
      confirmation_result = send_confirmation
      results << confirmation_result
      
      # Send device activation instructions if order has devices
      if @order.line_items.joins(:product).where.not(products: { device_type_id: nil }).exists?
        activation_result = send_activation_instructions
        results << activation_result
      end

      # Determine overall success
      successful_emails = results.count { |r| r[:success] }
      total_emails = results.count

      if successful_emails == total_emails
        success(
          message: "All order emails sent successfully (#{successful_emails}/#{total_emails})",
          email_results: results,
          total_sent: successful_emails
        )
      else
        failure(
          "Some emails failed to send (#{successful_emails}/#{total_emails} successful)",
          email_results: results,
          partial_success: true
        )
      end
    end

    private

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message, additional_data = {})
      { success: false, error: message }.merge(additional_data)
    end
  end
end