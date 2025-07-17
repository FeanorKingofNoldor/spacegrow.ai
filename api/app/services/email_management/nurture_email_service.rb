# app/services/email_management/nurture_email_service.rb
module EmailManagement
  class NurtureEmailService < ApplicationService
    
    # ===== LONG-TERM NURTURE SEQUENCE =====
    
    def self.send_educational_content(user)
      new(user).send_educational_content
    end

    def self.send_case_studies(user)
      new(user).send_case_studies
    end

    def self.send_seasonal_promotion(user)
      new(user).send_seasonal_promotion
    end

    def self.send_win_back_campaign(user)
      new(user).send_win_back_campaign
    end

    def self.send_final_attempt(user)
      new(user).send_final_attempt
    end

    def initialize(user)
      @user = user
    end

    # Send educational content for users who haven't fully engaged
    def send_educational_content
      return failure('User email not found') unless @user.email.present?
      
      # ✅ CHECK: Marketing preferences
      unless user_opted_into_marketing?
        return success_with_skip('User not opted into marketing emails')
      end

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      # Determine content based on user's journey
      content_data = generate_educational_content_data

      begin
        Rails.logger.info "🌱 [NurtureEmailService] Sending educational content to user #{@user.id}"
        
        NurtureMailer.educational_content(@user, content_data).deliver_now
        track_email_sent!('educational_content')
        
        success(
          message: "Educational content email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'nurture_educational_content',
          content_type: content_data[:topic]
        )
      rescue => e
        Rails.logger.error "🌱 [NurtureEmailService] Failed to send educational content to user #{@user.id}: #{e.message}"
        failure("Failed to send educational content: #{e.message}")
      end
    end

    # Send case studies showing ROI and success stories
    def send_case_studies
      return failure('User email not found') unless @user.email.present?
      
      unless user_opted_into_marketing?
        return success_with_skip('User not opted into marketing emails')
      end

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      case_study_data = generate_case_study_data

      begin
        Rails.logger.info "🌱 [NurtureEmailService] Sending case studies to user #{@user.id}"
        
        NurtureMailer.case_studies(@user, case_study_data).deliver_now
        track_email_sent!('case_studies')
        
        success(
          message: "Case studies email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'nurture_case_studies',
          case_study_count: case_study_data[:studies].length
        )
      rescue => e
        Rails.logger.error "🌱 [NurtureEmailService] Failed to send case studies to user #{@user.id}: #{e.message}"
        failure("Failed to send case studies: #{e.message}")
      end
    end

    # Send seasonal promotions and special offers
    def send_seasonal_promotion
      return failure('User email not found') unless @user.email.present?
      
      unless user_opted_into_marketing?
        return success_with_skip('User not opted into marketing emails')
      end

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      promotion_data = generate_seasonal_promotion_data

      begin
        Rails.logger.info "🌱 [NurtureEmailService] Sending seasonal promotion to user #{@user.id}"
        
        NurtureMailer.seasonal_promotion(@user, promotion_data).deliver_now
        track_email_sent!('seasonal_promotion')
        
        success(
          message: "Seasonal promotion email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'nurture_seasonal_promotion',
          promotion_type: promotion_data[:promotion_type],
          discount_percent: promotion_data[:discount_percent]
        )
      rescue => e
        Rails.logger.error "🌱 [NurtureEmailService] Failed to send seasonal promotion to user #{@user.id}: #{e.message}"
        failure("Failed to send seasonal promotion: #{e.message}")
      end
    end

    # Win-back campaign for inactive users
    def send_win_back_campaign
      return failure('User email not found') unless @user.email.present?
      
      unless user_opted_into_marketing?
        return success_with_skip('User not opted into marketing emails')
      end

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      campaign_data = generate_win_back_campaign_data

      begin
        Rails.logger.info "🌱 [NurtureEmailService] Sending win-back campaign to user #{@user.id}"
        
        NurtureMailer.win_back_campaign(@user, campaign_data).deliver_now
        track_email_sent!('win_back_campaign')
        
        success(
          message: "Win-back campaign email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'nurture_win_back_campaign',
          incentive_type: campaign_data[:incentive_type],
          incentive_value: campaign_data[:incentive_value]
        )
      rescue => e
        Rails.logger.error "🌱 [NurtureEmailService] Failed to send win-back campaign to user #{@user.id}: #{e.message}"
        failure("Failed to send win-back campaign: #{e.message}")
      end
    end

    # Final attempt with strong incentive
    def send_final_attempt
      return failure('User email not found') unless @user.email.present?
      
      unless user_opted_into_marketing?
        return success_with_skip('User not opted into marketing emails')
      end

      preference_check = NotificationManagement::PreferenceService.should_send_email?(
        @user, 
        'marketing_tips'
      )
      
      unless preference_check[:should_send]
        return success_with_skip(preference_check[:message])
      end

      incentive_data = generate_final_attempt_data

      begin
        Rails.logger.info "🌱 [NurtureEmailService] Sending final attempt to user #{@user.id}"
        
        NurtureMailer.final_attempt(@user, incentive_data).deliver_now
        track_email_sent!('final_attempt')
        
        # Mark user as having completed the nurture sequence
        mark_nurture_sequence_completed

        success(
          message: "Final attempt email sent to #{@user.email}",
          email_address: @user.email,
          email_type: 'nurture_final_attempt',
          incentive_type: incentive_data[:incentive_type],
          incentive_value: incentive_data[:incentive_value],
          sequence_completed: true
        )
      rescue => e
        Rails.logger.error "🌱 [NurtureEmailService] Failed to send final attempt to user #{@user.id}: #{e.message}"
        failure("Failed to send final attempt: #{e.message}")
      end
    end

    private

    # Check if user has opted into marketing
    def user_opted_into_marketing?
      @user.preferences.marketing_emails_opted_in
    end

    # Track email sent and update analytics
    def track_email_sent!(email_type)
      @user.preferences.track_email_sent!
      
      # Track in analytics service if available
      Analytics::EventTrackingService.track_user_activity(
        @user,
        'nurture_email_sent',
        {
          email_type: email_type,
          days_since_registration: (@user.created_at.to_date..Date.current).count,
          total_orders: @user.orders.count,
          has_devices: @user.devices.any?
        }
      ) if defined?(Analytics::EventTrackingService)
    end

    # Generate educational content based on user's profile
    def generate_educational_content_data
      days_since_registration = (Time.current - @user.created_at) / 1.day
      
      case days_since_registration.to_i
      when 0..14
        {
          topic: 'getting_started',
          title: 'Your First 2 Weeks with IoT Monitoring',
          content_focus: 'setup_basics',
          articles: [
            {
              title: '5 Best Practices for Device Placement',
              url: "#{Rails.application.config.app_host}/guides/device-placement",
              read_time: '3 min read'
            },
            {
              title: 'Understanding Your First Data Readings',
              url: "#{Rails.application.config.app_host}/guides/interpreting-data",
              read_time: '5 min read'
            }
          ]
        }
      when 15..30
        {
          topic: 'optimization',
          title: 'Optimizing Your IoT Setup for Better Results',
          content_focus: 'advanced_configuration',
          articles: [
            {
              title: 'Setting Up Custom Alert Thresholds',
              url: "#{Rails.application.config.app_host}/guides/custom-alerts",
              read_time: '4 min read'
            },
            {
              title: 'Creating Meaningful Reports from Your Data',
              url: "#{Rails.application.config.app_host}/guides/reporting",
              read_time: '6 min read'
            }
          ]
        }
      else
        {
          topic: 'advanced_strategies',
          title: 'Advanced IoT Monitoring Strategies',
          content_focus: 'scaling_optimization',
          articles: [
            {
              title: 'Scaling Your Monitoring Network',
              url: "#{Rails.application.config.app_host}/guides/scaling",
              read_time: '7 min read'
            },
            {
              title: 'Integrating IoT Data with Business Intelligence',
              url: "#{Rails.application.config.app_host}/guides/business-intelligence",
              read_time: '8 min read'
            }
          ]
        }
      end
    end

    # Generate case study data based on user's industry/interests
    def generate_case_study_data
      {
        theme: 'roi_success_stories',
        introduction: 'See how businesses like yours are achieving measurable results with IoT monitoring',
        studies: [
          {
            company: 'TechStart Manufacturing',
            industry: 'Manufacturing',
            challenge: 'Equipment downtime costing $50K per incident',
            solution: 'Predictive maintenance with temperature and vibration monitoring',
            results: [
              '85% reduction in unexpected downtime',
              '$200K+ saved in first 6 months',
              '99.2% equipment uptime achieved'
            ],
            quote: 'SpaceGrow helped us transform from reactive to predictive maintenance.',
            roi_percentage: 340
          },
          {
            company: 'GreenData Farms',
            industry: 'Agriculture',
            challenge: 'Crop loss due to environmental fluctuations',
            solution: 'Greenhouse monitoring with soil and air sensors',
            results: [
              '30% increase in crop yield',
              '50% reduction in water usage',
              '25% lower operating costs'
            ],
            quote: 'The data insights revolutionized how we manage our growing environment.',
            roi_percentage: 225
          }
        ]
      }
    end

    # Generate seasonal promotion data
    def generate_seasonal_promotion_data
      current_month = Time.current.month
      
      case current_month
      when 1, 2  # New Year
        {
          promotion_type: 'new_year_expansion',
          title: 'New Year, New Monitoring Goals',
          discount_percent: 20,
          valid_until: 1.month.from_now,
          focus: 'device_expansion',
          headline: 'Start the year right with expanded monitoring'
        }
      when 3, 4, 5  # Spring
        {
          promotion_type: 'spring_optimization',
          title: 'Spring Into Better Monitoring',
          discount_percent: 15,
          valid_until: 6.weeks.from_now,
          focus: 'plan_upgrade',
          headline: 'Perfect time to upgrade your monitoring capabilities'
        }
      when 6, 7, 8  # Summer
        {
          promotion_type: 'summer_reliability',
          title: 'Summer-Proof Your Operations',
          discount_percent: 25,
          valid_until: 2.months.from_now,
          focus: 'reliability_package',
          headline: 'Ensure peak performance during critical summer months'
        }
      when 9, 10, 11  # Fall
        {
          promotion_type: 'fall_preparation',
          title: 'Prepare for Peak Season',
          discount_percent: 20,
          valid_until: 6.weeks.from_now,
          focus: 'seasonal_preparation',
          headline: 'Get ready for your busiest time of year'
        }
      when 12  # Winter/Holiday
        {
          promotion_type: 'year_end_special',
          title: 'Year-End Monitoring Investment',
          discount_percent: 30,
          valid_until: 3.weeks.from_now,
          focus: 'year_end_planning',
          headline: 'Invest in next year\'s success with expanded monitoring'
        }
      end
    end

    # Generate win-back campaign data
    def generate_win_back_campaign_data
      {
        campaign_type: 'win_back_inactive',
        message_tone: 'we_miss_you',
        incentive_type: 'discount',
        incentive_value: '30% off first 3 months',
        valid_until: 2.weeks.from_now,
        what_they_missed: [
          'New advanced analytics dashboard',
          'Enhanced mobile app with push notifications',
          'Improved API with webhook support',
          'Expanded device compatibility'
        ],
        social_proof: {
          new_customers_count: 1247,
          data_points_processed: '2.3 million',
          average_roi: '250%'
        }
      }
    end

    # Generate final attempt data with strongest incentive
    def generate_final_attempt_data
      {
        campaign_type: 'final_opportunity',
        message_tone: 'last_chance',
        incentive_type: 'mega_discount',
        incentive_value: '50% off first 6 months',
        valid_until: 1.week.from_now,
        urgency_factors: [
          'Limited time offer expires soon',
          'This is our best offer of the year',
          'No future emails after this'
        ],
        testimonial: {
          customer_name: 'Sarah Chen',
          company: 'DataDriven Industries',
          quote: 'I waited too long to start monitoring. Don\'t make the same mistake I did.',
          result: 'Saved $180K in first year'
        }
      }
    end

    # Mark that user completed the nurture sequence
    def mark_nurture_sequence_completed
      # Store completion in Redis for tracking
      $redis.setex("nurture_sequence_completed:#{@user.id}", 1.year, Time.current.to_i) if defined?($redis)
      
      Rails.logger.info "🌱 [NurtureEmailService] Nurture sequence completed for user #{@user.id}"
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