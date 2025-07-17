# app/mailers/marketing_mailer.rb
class MarketingMailer < ApplicationMailer
  default from: 'marketing@spacegrow.ai'

  def pro_onboarding(order, pro_data)
    @order = order
    @user = order.user
    @pro_data = pro_data
    @device_count = pro_data[:device_count]
    @advanced_features = pro_data[:advanced_features]
    @next_steps = pro_data[:next_steps]
    @support_options = pro_data[:support_options]
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'marketing')
    
    mail(
      to: @user.email,
      subject: "🚀 Welcome to Pro-Level IoT Monitoring - #{@device_count} Devices Ready!"
    )
  end

  def accessory_follow_up(order, accessory_data)
    @order = order
    @user = order.user
    @accessory_data = accessory_data
    @accessories_purchased = accessory_data[:accessories_purchased]
    @device_recommendations = accessory_data[:device_recommendations]
    @use_cases = accessory_data[:use_cases]
    @special_offer = accessory_data[:special_offer]
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'marketing')
    
    mail(
      to: @user.email,
      subject: "Complete Your Monitoring Setup - Special Device Offers Inside"
    )
  end

  def device_promotion(user, order, promotion_data)
    @user = user
    @order = order
    @promotion_data = promotion_data
    @headline = promotion_data[:headline]
    @value_proposition = promotion_data[:value_proposition]
    @featured_devices = promotion_data[:featured_devices]
    @success_stories = promotion_data[:success_stories]
    @urgency_factors = promotion_data[:urgency_factors]
    
    # Calculate total potential savings
    @max_savings = @featured_devices.map { |d| d[:savings] }.max
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'marketing')
    
    mail(
      to: @user.email,
      subject: "🎯 #{@headline} - Save up to $#{@max_savings}"
    )
  end

  def final_device_follow_up(user, order, final_data)
    @user = user
    @order = order
    @final_data = final_data
    @engagement_summary = final_data[:engagement_summary]
    @strongest_incentive = final_data[:strongest_incentive]
    @risk_reversal = final_data[:risk_reversal]
    @scarcity_elements = final_data[:scarcity_elements]
    @social_proof = final_data[:social_proof]
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'marketing')
    
    mail(
      to: @user.email,
      subject: "⏰ Final Opportunity: #{@strongest_incentive[:discount_percent]}% Off IoT Devices"
    )
  end

  def pro_features_follow_up(user, pro_features_data)
    @user = user
    @pro_features_data = pro_features_data
    @current_plan = pro_features_data[:current_plan]
    @upgrade_target = pro_features_data[:upgrade_target]
    @features_comparison = pro_features_data[:features_comparison]
    @roi_calculator = pro_features_data[:roi_calculator]
    @upgrade_incentive = pro_features_data[:upgrade_incentive]
    
    # Calculate annual savings
    @annual_savings = @roi_calculator[:potential_savings]
                        .map { |s| s.scan(/\$[\d,]+/).first&.gsub(/[$,]/, '')&.to_i || 0 }
                        .sum * 12
    
    # Generate unsubscribe token
    @unsubscribe_token = generate_unsubscribe_token(@user, 'marketing')
    
    mail(
      to: @user.email,
      subject: "💡 Unlock #{@upgrade_target} Features - Potential $#{@annual_savings.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} Annual Savings"
    )
  end

  private

  # Generate unsubscribe token for marketing emails
  def generate_unsubscribe_token(user, email_type)
    payload = {
      user_id: user.id,
      email_type: email_type,
      exp: 1.year.from_now.to_i
    }
    
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  # Helper to format currency
  def format_currency(amount)
    number_to_currency(amount, precision: 0)
  end

  # Helper to format large numbers
  def format_number(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  # Helper to calculate percentage savings
  def calculate_savings_percent(regular_price, sale_price)
    return 0 if regular_price <= 0
    
    ((regular_price - sale_price).to_f / regular_price * 100).round
  end

  # Helper to generate shop URLs
  def shop_url(params = {})
    base_url = "#{Rails.application.config.app_host}/shop"
    return base_url if params.empty?
    
    query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    "#{base_url}?#{query_string}"
  end

  # Helper to generate unsubscribe URL
  def unsubscribe_url(token)
    "#{Rails.application.config.app_host}/unsubscribe?token=#{token}"
  end

  # Helper to track email opens (if analytics tracking is enabled)
  def tracking_pixel_url
    return '' unless defined?(Analytics::EmailTrackingService)
    
    tracking_id = SecureRandom.uuid
    Analytics::EmailTrackingService.create_tracking_pixel(@user.id, action_name, tracking_id)
    "#{Rails.application.config.app_host}/analytics/track/#{tracking_id}.gif"
  end
end