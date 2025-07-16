# app/models/concerns/emailable.rb
module Emailable
  extend ActiveSupport::Concern

  included do
    # Add virtual attributes for email tracking
    attr_accessor :confirmation_email_sent, :activation_emails_sent, :payment_failure_email_sent
    
    # Track email sending attempts
    after_update_commit :log_email_events, if: :should_log_email_events?
  end

  class_methods do
    def with_email_tracking
      # Scope for models that need email event tracking
      all
    end
  end

  # Email status tracking methods
  def mark_confirmation_email_sent!
    self.confirmation_email_sent = true
    Rails.logger.info "📧 [#{self.class.name}##{id}] Confirmation email marked as sent"
  end

  def mark_activation_emails_sent!(count = 1)
    self.activation_emails_sent = count
    Rails.logger.info "📧 [#{self.class.name}##{id}] #{count} activation email(s) marked as sent"
  end

  def mark_payment_failure_email_sent!
    self.payment_failure_email_sent = true
    Rails.logger.info "📧 [#{self.class.name}##{id}] Payment failure email marked as sent"
  end

  # Email delivery helpers
  def email_address
    case self
    when User
      email
    when Order
      user.email
    else
      respond_to?(:user) ? user&.email : nil
    end
  end

  def email_recipient_name
    case self
    when User
      display_name || email.split('@').first.capitalize
    when Order
      user.display_name || user.email.split('@').first.capitalize
    else
      respond_to?(:user) ? (user&.display_name || user&.email&.split('@')&.first&.capitalize) : 'Customer'
    end
  end

  # Batch email operations
  def send_confirmation_email
    return unless email_address.present?
    
    case self
    when Order
      EmailManagement::OrderEmailService.send_confirmation(self)
    else
      Rails.logger.warn "📧 [#{self.class.name}##{id}] No confirmation email method defined"
    end
  end

  def send_activation_emails
    return unless email_address.present?
    
    case self
    when Order
      EmailManagement::OrderEmailService.send_activation_instructions(self)
    else
      Rails.logger.warn "📧 [#{self.class.name}##{id}] No activation email method defined"
    end
  end

  private

  def should_log_email_events?
    confirmation_email_sent || activation_emails_sent || payment_failure_email_sent
  end

  def log_email_events
    events = []
    events << "confirmation_email" if confirmation_email_sent
    events << "#{activation_emails_sent}_activation_emails" if activation_emails_sent
    events << "payment_failure_email" if payment_failure_email_sent
    
    if events.any?
      Rails.logger.info "📧 [#{self.class.name}##{id}] Email events logged: #{events.join(', ')}"
    end
  end
end