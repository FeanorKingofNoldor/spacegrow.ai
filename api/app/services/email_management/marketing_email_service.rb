# app/services/email_management/marketing_email_service.rb
module EmailManagement
  class MarketingEmailService < ApplicationService
    
    # ===== ORDER-BASED MARKETING EMAILS =====
    
    def self.send_pro_onboarding(order)
      new(order).send_pro_onboarding
    end

    def self.send_accessory_follow_up(order)
      new(order).send_accessory_follow_up
    end

    def self.send_device_promotion(user, order)
      new(order, user).send_device_promotion
    end

    def self.send_final_device_follow_up(user, order, engagement_data)
      new(order, user).send_final_device_follow_up(engagement_data)
    end

    def self.send_pro_features_follow_up(user)
      new(nil, user).send_pro_features_follow_up
    end

    def initialize(order, user = nil)
      @order = order
      @user = user || order&.user
    end

    # Onboarding email for users who purchased many devices (pro-level users)
    def send_pro_onboarding
      return failure('Order not found') unless @order
      return failure('User email not found') unless @user.email.present?
      
      # Only send for orders with 3+ devices
      device_count = calculate_device_count
      return success_with_skip('Order does not qualify for pro onboarding') if device_count < 3

      # ✅ CHECK: Marketing preferences
      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      pro_data = generate_pro_onboarding_data

      begin
        Rails.logger.info "🎯 [MarketingEmailService] Sending pro onboarding for order #{@order.id}"
        
        MarketingMailer.pro_onboarding(@order, pro_data).deliver_now
        track_email_sent!('pro_onboarding')
        
        success(
          message: "Pro onboarding email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'marketing_pro_onboarding',
          device_count: device_count
        )
      rescue => e
        Rails.logger.error "🎯 [MarketingEmailService] Failed to send pro onboarding for order #{@order.id}: #{e.message}"
        failure("Failed to send pro onboarding email: #{e.message}")
      end
    end

    # Follow-up for users who only bought accessories
    def send_accessory_follow_up
      return failure('Order not found') unless @order
      return failure('User email not found') unless @user.email.present?
      
      # Only send for orders with accessories but no devices
      return success_with_skip('Order contains devices') if order_has_devices?

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      accessory_data = generate_accessory_follow_up_data

      begin
        Rails.logger.info "🎯 [MarketingEmailService] Sending accessory follow-up for order #{@order.id}"
        
        MarketingMailer.accessory_follow_up(@order, accessory_data).deliver_now
        track_email_sent!('accessory_follow_up')
        
        success(
          message: "Accessory follow-up email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'marketing_accessory_follow_up'
        )
      rescue => e
        Rails.logger.error "🎯 [MarketingEmailService] Failed to send accessory follow-up for order #{@order.id}: #{e.message}"
        failure("Failed to send accessory follow-up email: #{e.message}")
      end
    end

    # Promote devices to users who haven't purchased any yet
    def send_device_promotion
      return failure('User email not found') unless @user.email.present?
      
      # Only send to users without devices
      return success_with_skip('User already has devices') if @user.devices.any?

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      promotion_data = generate_device_promotion_data

      begin
        Rails.logger.info "🎯 [MarketingEmailService] Sending device promotion to user #{@user.id}"
        
        MarketingMailer.device_promotion(@user, @order, promotion_data).deliver_now
        track_email_sent!('device_promotion')
        
        success(
          message: "Device promotion email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'marketing_device_promotion'
        )
      rescue => e
        Rails.logger.error "🎯 [MarketingEmailService] Failed to send device promotion to user #{@user.id}: #{e.message}"
        failure("Failed to send device promotion email: #{e.message}")
      end
    end

    # Final follow-up for users who showed interest but haven't purchased devices
    def send_final_device_follow_up(engagement_data)
      return failure('User email not found') unless @user.email.present?
      
      # Only send to users who engaged but didn't convert
      return success_with_skip('User already has devices') if @user.devices.any?

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      final_data = generate_final_device_follow_up_data(engagement_data)

      begin
        Rails.logger.info "🎯 [MarketingEmailService] Sending final device follow-up to user #{@user.id}"
        
        MarketingMailer.final_device_follow_up(@user, @order, final_data).deliver_now
        track_email_sent!('final_device_follow_up')
        
        success(
          message: "Final device follow-up email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'marketing_final_device_follow_up'
        )
      rescue => e
        Rails.logger.error "🎯 [MarketingEmailService] Failed to send final device follow-up to user #{@user.id}: #{e.message}"
        failure("Failed to send final device follow-up email: #{e.message}")
      end
    end

    # Follow-up about pro features for basic users
    def send_pro_features_follow_up
      return failure('User email not found') unless @user.email.present?
      
      # Only send to users with basic plans
      return success_with_skip('User not on basic plan') unless user_on_basic_plan?

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      pro_features_data = generate_pro_features_data

      begin
        Rails.logger.info "🎯 [MarketingEmailService] Sending pro features follow-up to user #{@user.id}"
        
        MarketingMailer.pro_features_follow_up(@user, pro_features_data).deliver_now
        track_email_sent!('pro_features_follow_up')
        
        success(
          message: "Pro features follow-up email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'marketing_pro_features_follow_up'
        )
      rescue => e
        Rails.logger.error "🎯 [MarketingEmailService] Failed to send pro features follow-up to user #{@user.id}: #{e.message}"
        failure("Failed to send pro features follow-up email: #{e.message}")
      end
    end

    private

    # Calculate number of devices in order
    def calculate_device_count
      return 0 unless @order
      
      @order.line_items.joins(:product)
           .where.not(products: { device_type_id: nil })
           .sum(:quantity)
    end

    # Check if order contains devices
    def order_has_devices?
      calculate_device_count > 0
    end

    # Check if user is on basic plan
    def user_on_basic_plan?
      return false unless @user.subscription
      
      @user.subscription.plan.name.downcase.include?('basic')
    end

    # Track email sent
    def track_email_sent!(email_type)
      @user.preferences.track_email_sent!
      
      # Track in analytics if available
      Analytics::EventTrackingService.track_user_activity(
        @user,
        'marketing_email_sent',
        {
          email_type: email_type,
          order_id: @order&.id,
          total_orders: @user.orders.count,
          device_count: @user.devices.count
        }
      ) if defined?(Analytics::EventTrackingService)
    end

    # Generate pro onboarding data
    def generate_pro_onboarding_data
      device_count = calculate_device_count
      
      {
        device_count: device_count,
        title: "Welcome to Pro-Level IoT Monitoring",
        advanced_features: [
          {
            name: 'Multi-Device Dashboard',
            description: 'Monitor all your devices from a unified dashboard',
            benefit: 'Save 2+ hours daily on monitoring tasks'
          },
          {
            name: 'Advanced Analytics',
            description: 'Get insights across your entire device network',
            benefit: 'Identify patterns and optimize performance'
          },
          {
            name: 'Custom Reporting',
            description: 'Generate professional reports for stakeholders',
            benefit: 'Demonstrate ROI and operational efficiency'
          },
          {
            name: 'API Integration',
            description: 'Connect with your existing business systems',
            benefit: 'Automate workflows and reduce manual tasks'
          }
        ],
        next_steps: [
          'Complete device setup and activation',
          'Configure custom alert thresholds',
          'Set up your first automated report',
          'Explore API integration options'
        ],
        support_options: {
          priority_support: true,
          dedicated_onboarding: true,
          custom_training: device_count >= 10
        }
      }
    end

    # Generate accessory follow-up data
    def generate_accessory_follow_up_data
      {
        message_tone: 'helpful_suggestion',
        accessories_purchased: @order.line_items.includes(:product)
                                    .where(products: { device_type_id: nil })
                                    .map { |item| item.product.name },
        device_recommendations: [
          {
            name: 'Environment Monitor Pro',
            price: 199,
            perfect_for: 'Your new sensor accessories',
            features: ['Temperature & Humidity', 'Air Quality', 'Pressure Monitoring'],
            discount: 15
          },
          {
            name: 'Multi-Sensor Gateway',
            price: 149,
            perfect_for: 'Connecting multiple accessories',
            features: ['4 Sensor Inputs', 'WiFi Connectivity', 'Battery Backup'],
            discount: 10
          }
        ],
        use_cases: [
          'Complete environmental monitoring setup',
          'Redundant sensor configuration',
          'Expansion to multiple locations'
        ],
        special_offer: {
          discount_percent: 20,
          valid_until: 2.weeks.from_now,
          bundle_savings: 35
        }
      }
    end

    # Generate device promotion data
    def generate_device_promotion_data
      {
        promotion_type: 'first_device_special',
        target_audience: 'accessory_buyers',
        headline: 'Complete Your Monitoring Setup',
        value_proposition: 'Turn your accessories into a complete monitoring solution',
        featured_devices: [
          {
            name: 'Starter Monitoring Kit',
            regular_price: 299,
            sale_price: 199,
            savings: 100,
            includes: ['Main Hub', 'Temperature Sensor', 'Setup Guide'],
            perfect_for: 'First-time device buyers'
          },
          {
            name: 'Professional Monitoring System',
            regular_price: 499,
            sale_price: 349,
            savings: 150,
            includes: ['Advanced Hub', '3 Sensors', 'Mobile App', 'Priority Support'],
            perfect_for: 'Business applications'
          }
        ],
        success_stories: [
          {
            customer: 'Mike R.',
            result: 'Prevented $5K in damage with early warning system',
            timeframe: 'First month'
          },
          {
            customer: 'Lisa T.',
            result: 'Reduced energy costs by 30% with monitoring insights',
            timeframe: 'First quarter'
          }
        ],
        urgency_factors: [
          'Limited-time pricing',
          'Free shipping ends soon',
          'Only while supplies last'
        ]
      }
    end

    # Generate final device follow-up data
    def generate_final_device_follow_up_data(engagement_data)
      {
        engagement_summary: engagement_data,
        message_tone: 'final_opportunity',
        strongest_incentive: {
          discount_percent: 40,
          free_shipping: true,
          extended_warranty: true,
          valid_until: 1.week.from_now
        },
        risk_reversal: [
          '30-day money-back guarantee',
          'Free setup support',
          'One-year warranty included',
          'No commitment cancellation'
        ],
        scarcity_elements: [
          'This is our final offer',
          'Inventory levels are limited',
          'No additional discounts after this'
        ],
        social_proof: {
          recent_buyers: 89,
          average_rating: 4.8,
          satisfaction_rate: 96
        }
      }
    end

    # Generate pro features data
    def generate_pro_features_data
      current_plan = @user.subscription&.plan
      
      {
        current_plan: current_plan&.name || 'Basic',
        upgrade_target: 'Professional',
        features_comparison: [
          {
            feature: 'Device Limit',
            current: current_plan&.device_limit || 5,
            upgraded: 25,
            improvement: '5x more devices'
          },
          {
            feature: 'Data Retention',
            current: '30 days',
            upgraded: '1 year',
            improvement: '12x longer history'
          },
          {
            feature: 'API Access',
            current: 'Basic',
            upgraded: 'Full API + Webhooks',
            improvement: 'Complete integration'
          },
          {
            feature: 'Support',
            current: 'Email only',
            upgraded: 'Priority + Live Chat',
            improvement: 'Faster resolution'
          }
        ],
        roi_calculator: {
          monthly_cost_difference: 20,
          potential_savings: [
            'Prevent 1 downtime incident: $2,000+ saved',
            'Optimize energy usage: $150/month',
            'Automate monitoring tasks: 10 hours/month'
          ],
          payback_period: '2 weeks'
        },
        upgrade_incentive: {
          discount_percent: 25,
          first_month_free: true,
          valid_until: 2.weeks.from_now
        }
      }
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