# app/jobs/security/fraud_review_job.rb
module Security
  class FraudReviewJob < ApplicationJob
    queue_as :high_priority

    def perform(user_id, fraud_data = {})
      user = User.find_by(id: user_id)
      return unless user

      Rails.logger.info "🚨 [FraudReviewJob] Processing fraud review for user #{user.id}"
      Rails.logger.info "🚨 [FraudReviewJob] Fraud data: #{fraud_data}"

      # Calculate comprehensive fraud score
      fraud_score = calculate_fraud_score(user, fraud_data)
      
      # Determine risk level and actions
      risk_level = determine_risk_level(fraud_score)
      
      # Execute security measures based on risk level
      security_actions = execute_security_measures(user, risk_level, fraud_data)
      
      # Log fraud review results
      log_fraud_review(user, fraud_score, risk_level, security_actions, fraud_data)
      
      # Send notifications to security team if high risk
      if risk_level == 'high'
        notify_security_team(user, fraud_score, fraud_data)
      end

      Rails.logger.info "🚨 [FraudReviewJob] Fraud review completed for user #{user.id}, risk level: #{risk_level}"

    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "🚨 [FraudReviewJob] User #{user_id} not found"
    rescue => e
      Rails.logger.error "🚨 [FraudReviewJob] Error processing fraud review for user #{user_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    private

    def calculate_fraud_score(user, fraud_data)
      score = 0
      
      # Base score from trigger type
      case fraud_data[:trigger]
      when 'multiple_payment_failures'
        score += fraud_data[:failure_count] * 15
      when 'suspicious_device_activity'
        score += 25
      when 'high_value_failed_orders'
        score += 40
      when 'velocity_check'
        score += 30
      else
        score += 20
      end
      
      # User history factors
      score += calculate_user_history_score(user)
      
      # Recent activity factors
      score += calculate_recent_activity_score(user)
      
      # Geographic factors
      score += calculate_geographic_score(user)
      
      # Cap score at 100
      [score, 100].min
    end

    def calculate_user_history_score(user)
      score = 0
      
      # Account age (newer accounts are riskier)
      account_age_days = (Time.current - user.created_at) / 1.day
      if account_age_days < 1
        score += 30
      elsif account_age_days < 7
        score += 15
      elsif account_age_days < 30
        score += 5
      end
      
      # Order failure rate
      total_orders = user.orders.count
      failed_orders = user.orders.where(status: 'payment_failed').count
      
      if total_orders > 0
        failure_rate = failed_orders.to_f / total_orders
        score += (failure_rate * 40).round
      end
      
      # Multiple email addresses or pattern changes
      if user.email_was.present? && user.email_was != user.email
        score += 10
      end
      
      score
    end

    def calculate_recent_activity_score(user)
      score = 0
      
      # Recent order velocity
      recent_orders = user.orders.where('created_at > ?', 24.hours.ago).count
      if recent_orders > 5
        score += 25
      elsif recent_orders > 3
        score += 15
      end
      
      # Recent session count
      recent_sessions = user.user_sessions.where('created_at > ?', 24.hours.ago).count
      if recent_sessions > 10
        score += 20
      elsif recent_sessions > 5
        score += 10
      end
      
      score
    end

    def calculate_geographic_score(user)
      score = 0
      
      # Check for multiple IP addresses in short time
      recent_ips = user.user_sessions.where('created_at > ?', 24.hours.ago)
                      .distinct
                      .pluck(:ip_address)
                      .compact
      
      if recent_ips.count > 5
        score += 30
      elsif recent_ips.count > 3
        score += 15
      end
      
      score
    end

    def determine_risk_level(fraud_score)
      case fraud_score
      when 0..30
        'low'
      when 31..60
        'medium'
      when 61..80
        'high'
      else
        'critical'
      end
    end

    def execute_security_measures(user, risk_level, fraud_data)
      actions = []
      
      case risk_level
      when 'low'
        # Just log and monitor
        actions << 'logged_for_monitoring'
        
      when 'medium'
        # Add rate limiting
        actions << 'rate_limiting_applied'
        apply_rate_limiting(user)
        
      when 'high'
        # Temporarily suspend new orders
        actions << 'new_orders_suspended'
        suspend_new_orders(user)
        
        # Require additional verification
        actions << 'additional_verification_required'
        require_additional_verification(user)
        
      when 'critical'
        # Temporarily suspend account
        actions << 'account_suspended'
        suspend_account_temporarily(user)
        
        # Invalidate all sessions
        actions << 'all_sessions_invalidated'
        invalidate_all_sessions(user)
      end
      
      actions
    end

    def apply_rate_limiting(user)
      # Store enhanced rate limiting in Redis
      key = "fraud_rate_limit:#{user.id}"
      $redis.setex(key, 1.hour, 'enhanced_limiting')
      
      Rails.logger.info "🚨 [FraudReviewJob] Enhanced rate limiting applied to user #{user.id}"
    end

    def suspend_new_orders(user)
      # Store order suspension flag
      key = "fraud_order_suspension:#{user.id}"
      $redis.setex(key, 24.hours, 'orders_suspended')
      
      Rails.logger.info "🚨 [FraudReviewJob] New orders suspended for user #{user.id}"
    end

    def require_additional_verification(user)
      # Store verification requirement
      key = "fraud_verification_required:#{user.id}"
      $redis.setex(key, 72.hours, 'verification_required')
      
      Rails.logger.info "🚨 [FraudReviewJob] Additional verification required for user #{user.id}"
    end

    def suspend_account_temporarily(user)
      # Store account suspension (don't modify user directly)
      key = "fraud_account_suspension:#{user.id}"
      $redis.setex(key, 24.hours, 'account_suspended')
      
      Rails.logger.info "🚨 [FraudReviewJob] Account temporarily suspended for user #{user.id}"
    end

    def invalidate_all_sessions(user)
      # Use existing session management
      user.user_sessions.each do |session|
        JwtDenylist.create!(
          jti: session.jti,
          exp: session.expires_at
        )
      end
      
      user.user_sessions.destroy_all
      
      Rails.logger.info "🚨 [FraudReviewJob] All sessions invalidated for user #{user.id}"
    end

    def log_fraud_review(user, fraud_score, risk_level, security_actions, fraud_data)
      # Use existing analytics service
      Analytics::EventTrackingService.track_user_activity(
        user,
        'fraud_review_completed',
        {
          fraud_score: fraud_score,
          risk_level: risk_level,
          security_actions: security_actions,
          trigger: fraud_data[:trigger],
          trigger_data: fraud_data,
          review_timestamp: Time.current
        }
      )
    end

    def notify_security_team(user, fraud_score, fraud_data)
      # Send notification to security team (could be email, Slack, etc.)
      Rails.logger.warn "🚨 [FraudReviewJob] HIGH RISK USER DETECTED: User #{user.id} (#{user.email}) - Score: #{fraud_score}"
      Rails.logger.warn "🚨 [FraudReviewJob] Fraud data: #{fraud_data}"
      
      # TODO: Implement actual notification system
      # SecurityMailer.fraud_alert(user, fraud_score, fraud_data).deliver_now
      # or SlackNotificationService.send_fraud_alert(user, fraud_score, fraud_data)
    end
  end
end