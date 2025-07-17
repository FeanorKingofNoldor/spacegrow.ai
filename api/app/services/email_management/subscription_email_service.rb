# app/services/email_management/subscription_email_service.rb
module EmailManagement
  class SubscriptionEmailService < ApplicationService
    def self.send_payment_receipt(subscription, receipt_data)
      new(subscription).send_payment_receipt(receipt_data)
    end

    def self.send_payment_failed_notification(subscription, failure_data)
      new(subscription).send_payment_failed_notification(failure_data)
    end

    def self.send_suspension_notification(subscription, suspension_data)
      new(subscription).send_suspension_notification(suspension_data)
    end

    def self.send_reactivation_notification(subscription)
      new(subscription).send_reactivation_notification
    end

    def self.send_plan_change_confirmation(subscription, change_data)
      new(subscription).send_plan_change_confirmation(change_data)
    end

    def initialize(subscription)
      @subscription = subscription
      @user = subscription.user
    end

    def send_payment_receipt(receipt_data)
      return failure('Subscription must be active') unless @subscription.active?
      return failure('User email not found') unless @user.email.present?
      return failure('Receipt data required') unless receipt_data.present?

      # ✅ CHECK: Financial/billing notifications are mandatory but check for suppression
      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'financial_billing'
      )
      
      unless preference_check[:should_send]
        Rails.logger.info "📧 [SubscriptionEmailService] Skipping payment receipt for user #{@user.id}: #{preference_check[:message]}"
        return success_with_skip(preference_check[:message])
      end

      begin
        Rails.logger.info "📧 [SubscriptionEmailService] Sending payment receipt for subscription #{@subscription.id}"
        
        SubscriptionMailer.payment_receipt(@subscription, receipt_data).deliver_now
        
        # ✅ TRACK: Email was sent
        @user.preferences.track_email_sent!
        
        success(
          message: "Payment receipt sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'subscription_payment_receipt',
          subscription_id: @subscription.id,
          amount: receipt_data[:amount],
          invoice_id: receipt_data[:invoice_id]
        )
      rescue => e
        Rails.logger.error "📧 [SubscriptionEmailService] Failed to send payment receipt for subscription #{@subscription.id}: #{e.message}"
        failure("Failed to send payment receipt: #{e.message}")
      end
    end

    def send_payment_failed_notification(failure_data)
      return failure('User email not found') unless @user.email.present?
      return failure('Failure data required') unless failure_data.present?

      # ✅ CHECK: Financial/billing notifications (should almost always send)
      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'financial_billing',
        { urgent: true, bypass_rate_limit: true } # Critical billing issue
      )
      
      unless preference_check[:should_send]
        Rails.logger.warn "📧 [SubscriptionEmailService] User has suppressed critical billing notification: #{preference_check[:message]}"
        # Still might want to send this even if suppressed due to critical nature
      end

      begin
        Rails.logger.info "📧 [SubscriptionEmailService] Sending payment failure notification for subscription #{@subscription.id}"
        
        SubscriptionMailer.payment_failed(@subscription, failure_data).deliver_now
        
        # Update subscription status if not already marked
        @subscription.update!(status: 'past_due') unless @subscription.past_due?
        
        # ✅ TRACK: Email was sent
        @user.preferences.track_email_sent!
        
        success(
          message: "Payment failure notification sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'subscription_payment_failed',
          subscription_id: @subscription.id,
          failure_reason: failure_data[:failure_reason],
          retry_url: failure_data[:retry_url]
        )
      rescue => e
        Rails.logger.error "📧 [SubscriptionEmailService] Failed to send payment failure notification for subscription #{@subscription.id}: #{e.message}"
        failure("Failed to send payment failure notification: #{e.message}")
      end
    end

    def send_suspension_notification(suspension_data)
      return failure('User email not found') unless @user.email.present?
      return failure('Suspension data required') unless suspension_data.present?

      # ✅ CHECK: Account updates category
      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'account_updates',
        { urgent: true } # Suspension is urgent
      )
      
      unless preference_check[:should_send]
        Rails.logger.info "📧 [SubscriptionEmailService] Skipping suspension notification for user #{@user.id}: #{preference_check[:message]}"
        return success_with_skip(preference_check[:message])
      end

      begin
        Rails.logger.info "📧 [SubscriptionEmailService] Sending suspension notification for subscription #{@subscription.id}"
        
        SubscriptionMailer.suspension_notification(@subscription, suspension_data).deliver_now
        
        # ✅ TRACK: Email was sent
        @user.preferences.track_email_sent!
        
        success(
          message: "Suspension notification sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'subscription_suspension',
          subscription_id: @subscription.id,
          suspension_reason: suspension_data[:reason],
          grace_period_days: suspension_data[:grace_period_days] || 7,
          reactivation_url: suspension_data[:reactivation_url]
        )
      rescue => e
        Rails.logger.error "📧 [SubscriptionEmailService] Failed to send suspension notification for subscription #{@subscription.id}: #{e.message}"
        failure("Failed to send suspension notification: #{e.message}")
      end
    end

    def send_reactivation_notification
      return failure('User email not found') unless @user.email.present?

      # ✅ CHECK: Account updates category
      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'account_updates'
      )
      
      unless preference_check[:should_send]
        Rails.logger.info "📧 [SubscriptionEmailService] Skipping reactivation notification for user #{@user.id}: #{preference_check[:message]}"
        return success_with_skip(preference_check[:message])
      end

      begin
        Rails.logger.info "📧 [SubscriptionEmailService] Sending reactivation notification for subscription #{@subscription.id}"
        
        SubscriptionMailer.reactivation_notification(@subscription).deliver_now
        
        # ✅ TRACK: Email was sent
        @user.preferences.track_email_sent!
        
        success(
          message: "Reactivation notification sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'subscription_reactivation',
          subscription_id: @subscription.id,
          plan_name: @subscription.plan.name
        )
      rescue => e
        Rails.logger.error "📧 [SubscriptionEmailService] Failed to send reactivation notification for subscription #{@subscription.id}: #{e.message}"
        failure("Failed to send reactivation notification: #{e.message}")
      end
    end

    def send_plan_change_confirmation(change_data)
      return failure('User email not found') unless @user.email.present?
      return failure('Change data required') unless change_data.present?

      # ✅ CHECK: Account updates category
      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'account_updates'
      )
      
      unless preference_check[:should_send]
        Rails.logger.info "📧 [SubscriptionEmailService] Skipping plan change confirmation for user #{@user.id}: #{preference_check[:message]}"
        return success_with_skip(preference_check[:message])
      end

      begin
        Rails.logger.info "📧 [SubscriptionEmailService] Sending plan change confirmation for subscription #{@subscription.id}"
        
        SubscriptionMailer.plan_change_confirmation(@subscription, change_data).deliver_now
        
        # ✅ TRACK: Email was sent
        @user.preferences.track_email_sent!
        
        success(
          message: "Plan change confirmation sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'subscription_plan_change',
          subscription_id: @subscription.id,
          old_plan: change_data[:old_plan],
          new_plan: change_data[:new_plan],
          effective_date: change_data[:effective_date]
        )
      rescue => e
        Rails.logger.error "📧 [SubscriptionEmailService] Failed to send plan change confirmation for subscription #{@subscription.id}: #{e.message}"
        failure("Failed to send plan change confirmation: #{e.message}")
      end
    end

    # ===== BATCH OPERATIONS =====

    def send_billing_cycle_complete(billing_data)
      return failure('User email not found') unless @user.email.present?
      return failure('Billing data required') unless billing_data.present?

      results = []

      # Send payment receipt if payment succeeded
      if billing_data[:payment_succeeded]
        receipt_result = send_payment_receipt(billing_data[:receipt_data])
        results << receipt_result
      end

      # Send any plan change confirmations if applicable
      if billing_data[:plan_changed]
        change_result = send_plan_change_confirmation(billing_data[:change_data])
        results << change_result
      end

      # Determine overall success
      successful_emails = results.count { |r| r[:success] }
      total_emails = results.count

      if total_emails == 0
        success(message: 'No billing emails needed')
      elsif successful_emails == total_emails
        success(
          message: "All billing emails sent successfully (#{successful_emails}/#{total_emails})",
          email_results: results,
          total_sent: successful_emails
        )
      else
        failure(
          "Some billing emails failed to send (#{successful_emails}/#{total_emails} successful)",
          email_results: results,
          partial_success: true
        )
      end
    end

    # ===== ANALYTICS HELPERS =====

    def track_subscription_email(email_type, additional_data = {})
      Analytics::EventTrackingService.track_user_activity(
        @user,
        'subscription_email_sent',
        {
          email_type: email_type,
          subscription_id: @subscription.id,
          plan_name: @subscription.plan.name,
          subscription_status: @subscription.status
        }.merge(additional_data)
      )
    end

    private

    def success(data)
      # Track analytics for successful emails
      track_subscription_email(data[:email_type], {
        success: true,
        email_address: data[:email_address]
      }) if data[:email_type]
      
      { success: true }.merge(data)
    end

    def failure(message, additional_data = {})
      Rails.logger.error "📧 [SubscriptionEmailService] #{message}"
      { success: false, error: message }.merge(additional_data)
    end

    def success_with_skip(message)
      success(
        message: message,
        email_sent: false,
        skipped: true
      )
    end
  end
end