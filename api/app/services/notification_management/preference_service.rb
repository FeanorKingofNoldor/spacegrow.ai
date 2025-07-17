# app/services/notification_management/preference_service.rb
module NotificationManagement
  class PreferenceService < ApplicationService
    
    # ===== CLASS METHODS FOR DECISION MAKING =====
    
    # Check if email should be sent for a user and category
    def self.should_send_email?(user, category, context = {})
      new(user).should_send_email?(category, context)
    end
    
    # Check if in-app notification should be sent
    def self.should_send_inapp?(user, category, context = {})
      new(user).should_send_inapp?(category, context)
    end
    
    # Update user preferences with validation
    def self.update_preferences(user, preferences_hash)
      new(user).update_preferences(preferences_hash)
    end
    
    # Opt user into marketing with tracking
    def self.opt_into_marketing(user, source = 'user_action')
      new(user).opt_into_marketing(source)
    end
    
    # Opt user out of marketing with tracking
    def self.opt_out_of_marketing(user, unsubscribe_reason = nil)
      new(user).opt_out_of_marketing(unsubscribe_reason)
    end
    
    # Bulk operations for admin/system use
    def self.bulk_update_marketing_preferences(user_ids, opted_in:, source: 'admin_action')
      if opted_in
        UserNotificationPreference.bulk_opt_in_marketing(user_ids, source)
      else
        UserNotificationPreference.bulk_opt_out_marketing(user_ids, source)
      end
      
      Rails.logger.info "📧 [PreferenceService] Bulk updated marketing preferences for #{user_ids.count} users (opted_in: #{opted_in})"
    end
    
    # ===== INSTANCE METHODS =====
    
    def initialize(user)
      @user = user
      @preferences = UserNotificationPreference.for_user(user)
    end
    
    # Determine if email should be sent
    def should_send_email?(category, context = {})
      category = category.to_s
      
      # Validate category exists
      unless UserNotificationPreference::CATEGORIES.key?(category)
        Rails.logger.warn "📧 [PreferenceService] Unknown notification category: #{category}"
        return failure("Unknown notification category: #{category}")
      end
      
      # Check if user has email preferences disabled for this category
      unless @preferences.email_enabled_for?(category)
        return success_with_skip("User has email notifications disabled for #{category}")
      end
      
      # Check if user is temporarily suppressed
      if @preferences.suppressed?
        return success_with_skip("User has temporarily suppressed all notifications until #{@preferences.suppress_all_until}")
      end
      
      # Check digest preferences for non-critical categories
      if should_defer_to_digest?(category, context)
        return success_with_skip("Notification deferred to #{@preferences.digest_frequency} digest")
      end
      
      # Check rate limiting for high-frequency categories
      if rate_limited?(category, context)
        return success_with_skip("Rate limited for category #{category}")
      end
      
      # Check timezone considerations for non-urgent notifications
      if should_respect_quiet_hours?(category, context)
        return success_with_skip("Respecting user's quiet hours")
      end
      
      # All checks passed - send email
      success_with_send("Email approved for category #{category}")
    end
    
    # Determine if in-app notification should be sent
    def should_send_inapp?(category, context = {})
      category = category.to_s
      
      # Validate category exists
      unless UserNotificationPreference::CATEGORIES.key?(category)
        Rails.logger.warn "📧 [PreferenceService] Unknown notification category: #{category}"
        return failure("Unknown notification category: #{category}")
      end
      
      # Check if user has in-app preferences disabled for this category
      unless @preferences.inapp_enabled_for?(category)
        return success_with_skip("User has in-app notifications disabled for #{category}")
      end
      
      # Check if user is temporarily suppressed
      if @preferences.suppressed?
        return success_with_skip("User has temporarily suppressed all notifications until #{@preferences.suppress_all_until}")
      end
      
      # In-app notifications are generally less restricted than emails
      success_with_send("In-app notification approved for category #{category}")
    end
    
    # Update user notification preferences
    def update_preferences(preferences_hash)
      begin
        # Validate input structure
        unless preferences_hash.is_a?(Hash)
          return failure("Preferences must be provided as a hash")
        end
        
        updates = {}
        
        # Process category preferences
        if preferences_hash[:categories].present?
          preferences_hash[:categories].each do |category, settings|
            category = category.to_s
            
            # Skip unknown categories
            unless UserNotificationPreference::CATEGORIES.key?(category)
              Rails.logger.warn "📧 [PreferenceService] Skipping unknown category: #{category}"
              next
            end
            
            # Skip non-controllable categories
            unless @preferences.user_controllable?(category)
              Rails.logger.warn "📧 [PreferenceService] User cannot control category: #{category}"
              next
            end
            
            # Update email preference
            if settings[:email].present?
              email_attr = "#{category}_email"
              updates[email_attr] = ActiveModel::Type::Boolean.new.cast(settings[:email])
            end
            
            # Update in-app preference
            if settings[:inapp].present?
              inapp_attr = "#{category}_inapp"
              updates[inapp_attr] = ActiveModel::Type::Boolean.new.cast(settings[:inapp])
            end
          end
        end
        
        # Process digest preferences
        if preferences_hash[:digest_frequency].present?
          frequency = preferences_hash[:digest_frequency].to_s
          if UserNotificationPreference::DIGEST_FREQUENCIES.key?(frequency)
            updates[:digest_frequency] = frequency
          end
        end
        
        if preferences_hash[:digest_time].present?
          begin
            time_str = preferences_hash[:digest_time].to_s
            updates[:digest_time] = Time.parse(time_str).strftime('%H:%M:%S')
          rescue ArgumentError
            Rails.logger.warn "📧 [PreferenceService] Invalid digest_time format: #{preferences_hash[:digest_time]}"
          end
        end
        
        if preferences_hash[:digest_day_of_week].present?
          day = preferences_hash[:digest_day_of_week].to_i
          updates[:digest_day_of_week] = day if (1..7).include?(day)
        end
        
        # Process escalation preferences
        if preferences_hash[:enable_escalation].present?
          updates[:enable_escalation] = ActiveModel::Type::Boolean.new.cast(preferences_hash[:enable_escalation])
        end
        
        if preferences_hash[:escalation_delay_minutes].present?
          delay = preferences_hash[:escalation_delay_minutes].to_i
          updates[:escalation_delay_minutes] = delay if (15..1440).include?(delay)
        end
        
        # Note: timezone and language are managed at the user level
        
        # Apply updates
        if updates.any?
          @preferences.update!(updates)
          Rails.logger.info "📧 [PreferenceService] Updated preferences for user #{@user.id}: #{updates.keys.join(', ')}"
        end
        
        success(
          message: "Preferences updated successfully",
          updated_fields: updates.keys,
          preferences: @preferences.to_preferences_hash
        )
        
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "📧 [PreferenceService] Failed to update preferences for user #{@user.id}: #{e.message}"
        failure("Failed to update preferences: #{e.message}")
      rescue => e
        Rails.logger.error "📧 [PreferenceService] Unexpected error updating preferences for user #{@user.id}: #{e.message}"
        failure("An unexpected error occurred while updating preferences")
      end
    end
    
    # Opt user into marketing emails
    def opt_into_marketing(source = 'user_action')
      begin
        @preferences.opt_into_marketing(source)
        
        Rails.logger.info "📧 [PreferenceService] User #{@user.id} opted into marketing emails (source: #{source})"
        
        success(
          message: "Successfully opted into marketing emails",
          opted_in_at: @preferences.marketing_opted_in_at,
          source: source
        )
      rescue => e
        Rails.logger.error "📧 [PreferenceService] Failed to opt user #{@user.id} into marketing: #{e.message}"
        failure("Failed to opt into marketing emails: #{e.message}")
      end
    end
    
    # Opt user out of marketing emails
    def opt_out_of_marketing(unsubscribe_reason = nil)
      begin
        @preferences.opt_out_of_marketing
        
        # Track unsubscribe reason if provided
        if unsubscribe_reason.present?
          # Could store this in a separate unsubscribe tracking table
          Rails.logger.info "📧 [PreferenceService] User #{@user.id} opted out of marketing emails (reason: #{unsubscribe_reason})"
        else
          Rails.logger.info "📧 [PreferenceService] User #{@user.id} opted out of marketing emails"
        end
        
        success(
          message: "Successfully opted out of marketing emails",
          opted_out_at: @preferences.marketing_opted_out_at,
          reason: unsubscribe_reason
        )
      rescue => e
        Rails.logger.error "📧 [PreferenceService] Failed to opt user #{@user.id} out of marketing: #{e.message}"
        failure("Failed to opt out of marketing emails: #{e.message}")
      end
    end
    
    # Get complete user preferences
    def get_preferences
      success(preferences: @preferences.to_preferences_hash)
    end
    
    # Temporarily suppress all notifications
    def suppress_notifications(duration: 1.hour, reason: nil)
      begin
        @preferences.suppress_notifications(duration: duration, reason: reason)
        
        Rails.logger.info "📧 [PreferenceService] User #{@user.id} suppressed notifications for #{duration} (reason: #{reason})"
        
        success(
          message: "Notifications suppressed successfully",
          suppressed_until: @preferences.suppress_all_until,
          reason: reason
        )
      rescue => e
        Rails.logger.error "📧 [PreferenceService] Failed to suppress notifications for user #{@user.id}: #{e.message}"
        failure("Failed to suppress notifications: #{e.message}")
      end
    end
    
    # Remove notification suppression
    def unsuppress_notifications
      begin
        @preferences.unsuppress_notifications
        
        Rails.logger.info "📧 [PreferenceService] User #{@user.id} removed notification suppression"
        
        success(message: "Notification suppression removed successfully")
      rescue => e
        Rails.logger.error "📧 [PreferenceService] Failed to remove suppression for user #{@user.id}: #{e.message}"
        failure("Failed to remove notification suppression: #{e.message}")
      end
    end
    
    # Check if escalation should occur from in-app to email
    def should_escalate_notification?(category, notification_created_at)
      if @preferences.should_escalate_to_email?(category, notification_created_at)
        success_with_send("Escalation approved for category #{category}")
      else
        success_with_skip("Escalation not needed for category #{category}")
      end
    end
    
    # Track that an email was sent
    def track_email_sent!
      @preferences.track_email_sent!
    end
    
    # Track that an in-app notification was sent
    def track_inapp_notification!
      @preferences.track_inapp_notification!
    end
    
    private
    
    # Check if notification should be deferred to digest
    def should_defer_to_digest?(category, context)
      # Never defer critical or mandatory categories
      return false if %w[security_auth financial_billing critical_device_alerts].include?(category)
      
      # Check if user wants digest delivery
      @preferences.digest_frequency != 'immediate' && 
      context[:urgent] != true
    end
    
    # Check if category is rate limited
    def rate_limited?(category, context)
      # For now, simple check - could be enhanced with Redis-based rate limiting
      return false if context[:bypass_rate_limit] == true
      
      # Check if too many emails sent recently for this category
      recent_limit = case category
      when 'device_management'
        5 # Max 5 device management emails per hour
      when 'system_notifications'
        3 # Max 3 system notifications per hour
      else
        10 # Default limit
      end
      
      # This is a simplified check - in production, you'd want more sophisticated rate limiting
      @preferences.last_email_sent_at.present? && 
      @preferences.last_email_sent_at > 1.hour.ago &&
      @preferences.total_emails_sent > recent_limit
    end
    
    # Check if we should respect quiet hours
    def should_respect_quiet_hours?(category, context)
      # Never respect quiet hours for critical categories
      return false if %w[security_auth financial_billing critical_device_alerts].include?(category)
      return false if context[:urgent] == true
      
      # Check user's local time
      local_time = @preferences.local_time
      
      # Quiet hours: 10 PM to 7 AM
      quiet_start = local_time.beginning_of_day + 22.hours
      quiet_end = local_time.beginning_of_day + 7.hours
      
      current_time = local_time
      current_time >= quiet_start || current_time <= quiet_end
    end
    
    # Success response for sending notification
    def success_with_send(message)
      success(
        should_send: true,
        action: 'send',
        message: message
      )
    end
    
    # Success response for skipping notification
    def success_with_skip(message)
      success(
        should_send: false,
        action: 'skip',
        message: message
      )
    end
  end
end