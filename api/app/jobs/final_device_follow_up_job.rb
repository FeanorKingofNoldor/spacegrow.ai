# app/jobs/final_device_follow_up_job.rb
class FinalDeviceFollowUpJob < ApplicationJob
  queue_as :default

  def perform(user_id, original_order_id)
    user = User.find_by(id: user_id)
    return unless user

    original_order = Order.find_by(id: original_order_id)
    return unless original_order

    Rails.logger.info "🎯 [FinalDeviceFollowUpJob] Processing final device follow-up for user #{user.id}"

    # Only send if user still has no devices
    if user.devices.any?
      Rails.logger.info "🎯 [FinalDeviceFollowUpJob] User #{user.id} now has devices, skipping final follow-up"
      return
    end

    # Don't send if user has made any device purchases since original order
    if user.orders.joins(:products)
           .where.not(products: { device_type_id: nil })
           .where('orders.created_at > ?', original_order.created_at)
           .exists?
      Rails.logger.info "🎯 [FinalDeviceFollowUpJob] User #{user.id} has made device purchases since, skipping"
      return
    end

    # Calculate user engagement and determine approach
    engagement_data = calculate_engagement_data(user, original_order)
    
    # Send final follow-up email
    result = EmailManagement::OrderEmailService.send_final_device_follow_up(user, original_order, engagement_data)
    
    if result[:success]
      Rails.logger.info "🎯 [FinalDeviceFollowUpJob] Final device follow-up email sent successfully for user #{user.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        user,
        'final_device_follow_up_sent',
        {
          original_order_id: original_order.id,
          days_since_first_purchase: (Time.current - original_order.created_at) / 1.day,
          email_sequence_stage: 'final',
          engagement_score: engagement_data[:engagement_score],
          recommended_approach: engagement_data[:approach],
          conversion_probability: engagement_data[:conversion_probability]
        }
      )

      # Move user to long-term nurture sequence
      LongTermNurtureSequenceJob.set(wait: 2.weeks).perform_later(user.id)
    else
      Rails.logger.error "🎯 [FinalDeviceFollowUpJob] Failed to send final device follow-up for user #{user.id}: #{result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🎯 [FinalDeviceFollowUpJob] User #{user_id} or Order #{original_order_id} not found"
  rescue => e
    Rails.logger.error "🎯 [FinalDeviceFollowUpJob] Error processing final device follow-up for user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def calculate_engagement_data(user, original_order)
    # Calculate comprehensive engagement metrics
    engagement_score = 0
    
    # Email engagement (if tracking is available)
    recent_sessions = user.user_sessions.where('created_at > ?', 1.week.ago).count
    engagement_score += [recent_sessions * 2, 20].min
    
    # Time spent on platform
    total_sessions = user.user_sessions.count
    engagement_score += [total_sessions, 30].min
    
    # Purchase behavior
    total_orders = user.orders.count
    engagement_score += total_orders * 10
    
    # Accessory investment
    accessory_value = user.orders.joins(:products)
                          .where(products: { device_type_id: nil })
                          .sum('line_items.price * line_items.quantity')
    engagement_score += [accessory_value.to_i / 10, 30].min
    
    # Account age
    account_age_days = (Time.current - user.created_at) / 1.day
    if account_age_days > 30
      engagement_score += 10
    elsif account_age_days > 14
      engagement_score += 5
    end
    
    # Determine approach based on engagement
    approach = determine_approach_strategy(engagement_score, user)
    
    # Calculate conversion probability
    conversion_probability = calculate_conversion_probability(engagement_score, user, original_order)
    
    {
      engagement_score: engagement_score,
      approach: approach,
      conversion_probability: conversion_probability,
      user_segment: determine_user_segment(engagement_score),
      recommended_incentive: calculate_recommended_incentive(engagement_score, accessory_value)
    }
  end

  def determine_approach_strategy(engagement_score, user)
    case engagement_score
    when 0..20
      'value_focused'     # Focus on value proposition and benefits
    when 21..40
      'social_proof'      # Show customer testimonials and case studies
    when 41..60
      'technical_specs'   # Detailed technical information
    when 61..80
      'incentive_based'   # Offer discounts or promotions
    else
      'premium_onboarding' # VIP treatment and premium features
    end
  end

  def calculate_conversion_probability(engagement_score, user, original_order)
    base_probability = 0.05 # 5% base conversion rate
    
    # Adjust based on engagement score
    engagement_multiplier = 1 + (engagement_score / 100.0)
    
    # Adjust based on accessory investment
    accessory_investment = original_order.total.to_f
    investment_multiplier = 1 + ([accessory_investment / 100, 0.5].min)
    
    # Adjust based on account age
    account_age_days = (Time.current - user.created_at) / 1.day
    if account_age_days > 30
      age_multiplier = 1.2
    elsif account_age_days > 14
      age_multiplier = 1.1
    else
      age_multiplier = 0.9
    end
    
    # Calculate final probability
    final_probability = base_probability * engagement_multiplier * investment_multiplier * age_multiplier
    
    # Cap at 50%
    [final_probability, 0.5].min
  end

  def determine_user_segment(engagement_score)
    case engagement_score
    when 0..20
      'low_engagement'
    when 21..40
      'moderate_engagement'
    when 41..60
      'high_engagement'
    when 61..80
      'very_high_engagement'
    else
      'premium_prospect'
    end
  end

  def calculate_recommended_incentive(engagement_score, accessory_value)
    # Base incentive on engagement and previous investment
    base_incentive = 10
    
    # Lower engagement users get higher incentives
    if engagement_score < 20
      base_incentive = 20
    elsif engagement_score < 40
      base_incentive = 15
    end
    
    # Higher accessory investment gets loyalty bonus
    if accessory_value > 100
      base_incentive += 5
    elsif accessory_value > 50
      base_incentive += 3
    end
    
    # Cap at 25%
    [base_incentive, 25].min
  end
end