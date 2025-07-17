# app/mailers/subscription_mailer.rb
class SubscriptionMailer < ApplicationMailer
  default from: 'billing@spacegrow.ai'

  def payment_receipt(subscription, receipt_data)
    @subscription = subscription
    @user = subscription.user
    @receipt_data = receipt_data
    @plan = subscription.plan
    @amount = receipt_data[:amount]
    @currency = receipt_data[:currency] || 'USD'
    @invoice_id = receipt_data[:invoice_id]
    @payment_date = receipt_data[:payment_date] || Time.current
    @period_start = receipt_data[:period_start]
    @period_end = receipt_data[:period_end]
    @next_billing_date = receipt_data[:next_billing_date] || subscription.current_period_end
    
    # Calculate billing period description
    @billing_period = calculate_billing_period(@period_start, @period_end)
    
    mail(
      to: @user.email,
      subject: "Payment Receipt - #{@plan.name} Plan (#{format_currency(@amount)})"
    )
  end

  def payment_failed(subscription, failure_data)
    @subscription = subscription
    @user = subscription.user
    @failure_data = failure_data
    @plan = subscription.plan
    @amount = failure_data[:amount]
    @currency = failure_data[:currency] || 'USD'
    @failure_reason = failure_data[:failure_reason]
    @retry_url = failure_data[:retry_url]
    @invoice_id = failure_data[:invoice_id]
    @grace_period_end = failure_data[:grace_period_end] || 7.days.from_now
    
    # Generate user-friendly failure message
    @user_friendly_message = generate_failure_message(@failure_reason)
    
    mail(
      to: @user.email,
      subject: "⚠️ Payment Failed - #{@plan.name} Plan (Action Required)"
    )
  end

  def suspension_notification(subscription, suspension_data)
    @subscription = subscription
    @user = subscription.user
    @suspension_data = suspension_data
    @plan = subscription.plan
    @suspension_reason = suspension_data[:reason]
    @grace_period_days = suspension_data[:grace_period_days] || 7
    @reactivation_url = suspension_data[:reactivation_url]
    @suspended_devices_count = suspension_data[:suspended_devices_count] || 0
    @can_reactivate_immediately = suspension_data[:can_reactivate_immediately] || true
    
    # Calculate when suspension becomes permanent
    @permanent_suspension_date = @grace_period_days.days.from_now
    
    mail(
      to: @user.email,
      subject: "🔒 SpaceGrow Service Suspended - #{@grace_period_days} Day Grace Period"
    )
  end

  def reactivation_notification(subscription)
    @subscription = subscription
    @user = subscription.user
    @plan = subscription.plan
    @reactivation_date = Time.current
    @next_billing_date = subscription.current_period_end
    @devices_count = @user.devices.operational.count
    
    # Calculate how long they were suspended
    @suspension_duration = calculate_suspension_duration(subscription)
    
    mail(
      to: @user.email,
      subject: "✅ Welcome Back! Your SpaceGrow Service is Active"
    )
  end

  def plan_change_confirmation(subscription, change_data)
    @subscription = subscription
    @user = subscription.user
    @change_data = change_data
    @old_plan = change_data[:old_plan]
    @new_plan = change_data[:new_plan]
    @effective_date = change_data[:effective_date]
    @proration_amount = change_data[:proration_amount]
    @next_billing_date = subscription.current_period_end
    
    # Determine if upgrade or downgrade
    @is_upgrade = @new_plan[:device_limit] > @old_plan[:device_limit]
    @is_downgrade = @new_plan[:device_limit] < @old_plan[:device_limit]
    
    # Calculate price difference
    @price_difference = (@new_plan[:monthly_price] - @old_plan[:monthly_price]).round(2)
    
    subject_prefix = @is_upgrade ? "🎉 Plan Upgraded" : (@is_downgrade ? "📋 Plan Changed" : "📋 Plan Updated")
    
    mail(
      to: @user.email,
      subject: "#{subject_prefix} - #{@new_plan[:name]} Plan Active"
    )
  end

  private

  def calculate_billing_period(period_start, period_end)
    return "Current billing period" unless period_start && period_end
    
    start_date = period_start.strftime('%B %d, %Y')
    end_date = period_end.strftime('%B %d, %Y')
    
    "#{start_date} - #{end_date}"
  end

  def format_currency(amount, currency = 'USD')
    case currency.upcase
    when 'USD'
      "$#{sprintf('%.2f', amount)}"
    when 'EUR'
      "€#{sprintf('%.2f', amount)}"
    when 'GBP'
      "£#{sprintf('%.2f', amount)}"
    else
      "#{currency.upcase} #{sprintf('%.2f', amount)}"
    end
  end

  def generate_failure_message(failure_reason)
    case failure_reason&.downcase
    when /insufficient.funds/, /declined/, /card.declined/
      "Your payment was declined by your bank. Please try a different payment method or contact your bank for assistance."
    when /expired.card/, /invalid.expiry/
      "Your card has expired. Please update your payment information with a valid card."
    when /incorrect.cvc/, /invalid.cvc/
      "The security code (CVC) was incorrect. Please check your card details and try again."
    when /authentication.required/, /requires.action/
      "Additional authentication is required. Please complete the verification process."
    when /processing.error/, /try.again/
      "There was a temporary processing error. Please try again in a few minutes."
    else
      "Your payment could not be processed. Please try again or contact support for assistance."
    end
  end

  def calculate_suspension_duration(subscription)
    # This would need to be tracked in the subscription model
    # For now, return a default message
    "a brief period"
  end

  def app_host
    Rails.application.config.app_host || 'https://spacegrow.ai'
  end

  def dashboard_url
    "#{app_host}/dashboard"
  end

  def billing_url
    "#{app_host}/billing"
  end

  def support_url
    "#{app_host}/support"
  end
end