# app/mailers/nurture_mailer.rb
class NurtureMailer < ApplicationMailer
  default from: 'growth@spacegrow.ai'

  def educational_content(user, content_data)
    @user = user
    @content_data = content_data
    @topic = content_data[:topic]
    @title = content_data[:title]
    @content_focus = content_data[:content_focus]
    @articles = content_data[:articles]
    
    # Calculate user journey metrics
    @days_since_registration = (Time.current - @user.created_at) / 1.day
    @total_orders = @user.orders.count
    @device_count = @user.devices.count
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'nurture')
    
    mail(
      to: @user.email,
      subject: "📚 #{@title} - Your IoT Learning Journey Continues"
    )
  end

  def case_studies(user, case_study_data)
    @user = user
    @case_study_data = case_study_data
    @theme = case_study_data[:theme]
    @introduction = case_study_data[:introduction]
    @studies = case_study_data[:studies]
    
    # Calculate average ROI across case studies
    @average_roi = @studies.map { |s| s[:roi_percentage] }.sum / @studies.length
    
    # Get the highest ROI for subject line
    @max_roi = @studies.map { |s| s[:roi_percentage] }.max
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'nurture')
    
    mail(
      to: @user.email,
      subject: "💼 Real Results: How Companies Achieved #{@max_roi}% ROI with IoT"
    )
  end

  def seasonal_promotion(user, promotion_data)
    @user = user
    @promotion_data = promotion_data
    @promotion_type = promotion_data[:promotion_type]
    @title = promotion_data[:title]
    @discount_percent = promotion_data[:discount_percent]
    @valid_until = promotion_data[:valid_until]
    @focus = promotion_data[:focus]
    @headline = promotion_data[:headline]
    
    # Generate urgency messaging
    @days_remaining = ((@valid_until - Time.current) / 1.day).ceil
    @urgency_message = generate_urgency_message(@days_remaining)
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'nurture')
    
    mail(
      to: @user.email,
      subject: "🌟 #{@title} - #{@discount_percent}% Off (#{@days_remaining} Days Left)"
    )
  end

  def win_back_campaign(user, campaign_data)
    @user = user
    @campaign_data = campaign_data
    @campaign_type = campaign_data[:campaign_type]
    @message_tone = campaign_data[:message_tone]
    @incentive_type = campaign_data[:incentive_type]
    @incentive_value = campaign_data[:incentive_value]
    @valid_until = campaign_data[:valid_until]
    @what_they_missed = campaign_data[:what_they_missed]
    @social_proof = campaign_data[:social_proof]
    
    # Calculate time since last login or activity
    @last_activity = @user.current_sign_in_at || @user.created_at
    @days_since_activity = (Time.current - @last_activity) / 1.day
    
    # Generate personalized "we miss you" message
    @personal_message = generate_personal_message(@days_since_activity)
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'nurture')
    
    mail(
      to: @user.email,
      subject: "🔄 We Miss You! Come Back to #{@incentive_value} Savings"
    )
  end

  def final_attempt(user, incentive_data)
    @user = user
    @incentive_data = incentive_data
    @campaign_type = incentive_data[:campaign_type]
    @message_tone = incentive_data[:message_tone]
    @incentive_type = incentive_data[:incentive_type]
    @incentive_value = incentive_data[:incentive_value]
    @valid_until = incentive_data[:valid_until]
    @urgency_factors = incentive_data[:urgency_factors]
    @testimonial = incentive_data[:testimonial]
    
    # Calculate final urgency metrics
    @hours_remaining = ((@valid_until - Time.current) / 1.hour).ceil
    @is_final_day = @hours_remaining <= 24
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'nurture')
    
    mail(
      to: @user.email,
      subject: "⚡ FINAL NOTICE: #{@incentive_value} Expires in #{@hours_remaining}h"
    )
  end

  private

  # Generate unsubscribe token for nurture emails
  def generate_unsubscribe_token(user, email_type)
    payload = {
      user_id: user.id,
      email_type: email_type,
      exp: 1.year.from_now.to_i
    }
    
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  # Generate urgency message based on days remaining
  def generate_urgency_message(days_remaining)
    case days_remaining
    when 0..1
      "⚡ ENDS TODAY!"
    when 2..3
      "⏰ Only #{days_remaining} days left"
    when 4..7
      "📅 Limited time: #{days_remaining} days remaining"
    else
      "🗓️ Valid for #{days_remaining} more days"
    end
  end

  # Generate personalized message based on activity
  def generate_personal_message(days_since_activity)
    case days_since_activity.to_i
    when 0..30
      "We noticed you haven't been back recently..."
    when 31..90
      "It's been a while since we've seen you..."
    when 91..180
      "We really miss having you as part of our community..."
    else
      "We'd love to welcome you back to SpaceGrow..."
    end
  end

  # Helper to format time remaining
  def format_time_remaining(time)
    distance_of_time_in_words(Time.current, time, include_seconds: false)
  end

  # Helper to format percentages
  def format_percentage(number)
    "#{number}%"
  end

  # Helper to generate shop URLs with UTM tracking
  def shop_url_with_tracking(campaign_name, source = 'email')
    "#{Rails.application.config.app_host}/shop?" \
    "utm_source=#{source}&" \
    "utm_medium=email&" \
    "utm_campaign=#{campaign_name}&" \
    "utm_content=#{action_name}"
  end

  # Helper to generate unsubscribe URL
  def unsubscribe_url(token)
    "#{Rails.application.config.app_host}/unsubscribe?token=#{token}"
  end

  # Helper for tracking email engagement
  def tracking_pixel_url
    return '' unless defined?(Analytics::EmailTrackingService)
    
    tracking_id = SecureRandom.uuid
    Analytics::EmailTrackingService.create_tracking_pixel(@user.id, action_name, tracking_id)
    "#{Rails.application.config.app_host}/analytics/track/#{tracking_id}.gif"
  end

  # Helper to get user's preferred name
  def user_display_name
    @user.display_name.presence || @user.email.split('@').first.titleize
  end

  # Helper to check if user has made recent purchases
  def recent_purchaser?
    @user.orders.where('created_at > ?', 3.months.ago).exists?
  end

  # Helper to get user's engagement level
  def user_engagement_level
    if @user.devices.any? && recent_purchaser?
      'high'
    elsif @user.orders.any?
      'medium'
    else
      'low'
    end
  end

  # Helper to generate CTA based on user engagement
  def primary_cta_text
    case user_engagement_level
    when 'high'
      'Explore Advanced Features'
    when 'medium'
      'Expand Your Monitoring'
    else
      'Start Your Journey'
    end
  end
end