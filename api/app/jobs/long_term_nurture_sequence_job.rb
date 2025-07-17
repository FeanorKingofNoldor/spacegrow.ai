# app/jobs/long_term_nurture_sequence_job.rb
class LongTermNurtureSequenceJob < ApplicationJob
  queue_as :low_priority

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Processing long-term nurture for user #{user.id}"

    # Only continue if user still has no devices
    if user.devices.any?
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] User #{user.id} now has devices, ending nurture sequence"
      return
    end

    # Don't continue if user has made device purchases
    if user.orders.joins(:products).where.not(products: { device_type_id: nil }).any?
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] User #{user.id} has made device purchases, ending nurture sequence"
      return
    end

    # Calculate nurture stage and send appropriate content
    nurture_stage = determine_nurture_stage(user)
    
    case nurture_stage
    when 'educational_content'
      send_educational_content(user)
    when 'case_studies'
      send_case_studies(user)
    when 'seasonal_promotion'
      send_seasonal_promotion(user)
    when 'win_back_campaign'
      send_win_back_campaign(user)
    when 'final_attempt'
      send_final_attempt(user)
    else
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] User #{user.id} has completed nurture sequence"
      return
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🌱 [LongTermNurtureSequenceJob] User #{user_id} not found"
  rescue => e
    Rails.logger.error "🌱 [LongTermNurtureSequenceJob] Error processing long-term nurture for user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def determine_nurture_stage(user)
    # Determine stage based on user's journey timeline
    first_order_age = (Time.current - user.orders.first.created_at) / 1.day
    
    case first_order_age
    when 0..30
      'educational_content'
    when 31..60
      'case_studies'
    when 61..120
      'seasonal_promotion'
    when 121..180
      'win_back_campaign'
    when 181..365
      'final_attempt'
    else
      'completed'
    end
  end

  def send_educational_content(user)
    result = EmailManagement::NurtureEmailService.send_educational_content(user)
    
    if result[:success]
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Educational content sent to user #{user.id}"
      
      # Track analytics
      track_nurture_email(user, 'educational_content')
      
      # Schedule next nurture email
      LongTermNurtureSequenceJob.set(wait: 2.weeks).perform_later(user.id)
    else
      Rails.logger.error "🌱 [LongTermNurtureSequenceJob] Failed to send educational content to user #{user.id}: #{result[:error]}"
    end
  end

  def send_case_studies(user)
    result = EmailManagement::NurtureEmailService.send_case_studies(user)
    
    if result[:success]
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Case studies sent to user #{user.id}"
      
      # Track analytics
      track_nurture_email(user, 'case_studies')
      
      # Schedule next nurture email
      LongTermNurtureSequenceJob.set(wait: 3.weeks).perform_later(user.id)
    else
      Rails.logger.error "🌱 [LongTermNurtureSequenceJob] Failed to send case studies to user #{user.id}: #{result[:error]}"
    end
  end

  def send_seasonal_promotion(user)
    result = EmailManagement::NurtureEmailService.send_seasonal_promotion(user)
    
    if result[:success]
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Seasonal promotion sent to user #{user.id}"
      
      # Track analytics
      track_nurture_email(user, 'seasonal_promotion')
      
      # Schedule next nurture email
      LongTermNurtureSequenceJob.set(wait: 4.weeks).perform_later(user.id)
    else
      Rails.logger.error "🌱 [LongTermNurtureSequenceJob] Failed to send seasonal promotion to user #{user.id}: #{result[:error]}"
    end
  end

  def send_win_back_campaign(user)
    result = EmailManagement::NurtureEmailService.send_win_back_campaign(user)
    
    if result[:success]
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Win-back campaign sent to user #{user.id}"
      
      # Track analytics
      track_nurture_email(user, 'win_back_campaign')
      
      # Schedule final attempt
      LongTermNurtureSequenceJob.set(wait: 6.weeks).perform_later(user.id)
    else
      Rails.logger.error "🌱 [LongTermNurtureSequenceJob] Failed to send win-back campaign to user #{user.id}: #{result[:error]}"
    end
  end

  def send_final_attempt(user)
    result = EmailManagement::NurtureEmailService.send_final_attempt(user)
    
    if result[:success]
      Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Final attempt sent to user #{user.id}"
      
      # Track analytics
      track_nurture_email(user, 'final_attempt')
      
      # Mark user as completed nurture sequence
      mark_nurture_sequence_completed(user)
    else
      Rails.logger.error "🌱 [LongTermNurtureSequenceJob] Failed to send final attempt to user #{user.id}: #{result[:error]}"
    end
  end

  def track_nurture_email(user, email_type)
    Analytics::EventTrackingService.track_user_activity(
      user,
      'nurture_email_sent',
      {
        email_type: email_type,
        days_since_first_purchase: (Time.current - user.orders.first.created_at) / 1.day,
        total_orders: user.orders.count,
        nurture_stage: email_type
      }
    )
  end

  def mark_nurture_sequence_completed(user)
    # Store completion in Redis for tracking
    key = "nurture_sequence_completed:#{user.id}"
    $redis.setex(key, 1.year, Time.current.to_i)
    
    # Final analytics tracking
    Analytics::EventTrackingService.track_user_activity(
      user,
      'nurture_sequence_completed',
      {
        total_days_in_sequence: (Time.current - user.orders.first.created_at) / 1.day,
        total_orders: user.orders.count,
        total_spent: user.orders.sum(&:total),
        converted_to_device_owner: user.devices.any?
      }
    )
    
    Rails.logger.info "🌱 [LongTermNurtureSequenceJob] Nurture sequence completed for user #{user.id}"
  end
end