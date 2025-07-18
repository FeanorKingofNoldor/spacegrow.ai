# app/services/admin/admin_notification_service.rb
module Admin
  class AdminNotificationService < ApplicationService
    def initialize(admin_user = nil)
      @admin_user = admin_user
    end

    def send_critical_alert(alert_type, data = {})
      begin
        alert = create_admin_alert(alert_type, 'critical', data)
        
        # Send immediate notifications for critical alerts
        notifications_sent = []
        
        # Email notification
        if should_send_email_alert?(alert_type, 'critical')
          email_result = send_email_alert(alert, data)
          notifications_sent << { type: 'email', success: email_result[:success] }
        end
        
        # Slack notification (if configured)
        if should_send_slack_alert?(alert_type, 'critical')
          slack_result = send_slack_alert(alert, data)
          notifications_sent << { type: 'slack', success: slack_result[:success] }
        end
        
        # SMS notification for critical alerts (if configured)
        if should_send_sms_alert?(alert_type, 'critical')
          sms_result = send_sms_alert(alert, data)
          notifications_sent << { type: 'sms', success: sms_result[:success] }
        end
        
        # In-app notification
        in_app_result = create_in_app_notification(alert, data)
        notifications_sent << { type: 'in_app', success: in_app_result[:success] }
        
        success(
          message: "Critical alert sent successfully",
          alert: serialize_alert(alert),
          notifications_sent: notifications_sent,
          alert_id: alert.id
        )
      rescue => e
        Rails.logger.error "Critical alert error: #{e.message}"
        failure("Failed to send critical alert: #{e.message}")
      end
    end

    def send_warning_alert(alert_type, data = {})
      begin
        alert = create_admin_alert(alert_type, 'warning', data)
        
        notifications_sent = []
        
        # For warnings, typically just email and in-app
        if should_send_email_alert?(alert_type, 'warning')
          email_result = send_email_alert(alert, data)
          notifications_sent << { type: 'email', success: email_result[:success] }
        end
        
        in_app_result = create_in_app_notification(alert, data)
        notifications_sent << { type: 'in_app', success: in_app_result[:success] }
        
        success(
          message: "Warning alert sent successfully",
          alert: serialize_alert(alert),
          notifications_sent: notifications_sent,
          alert_id: alert.id
        )
      rescue => e
        Rails.logger.error "Warning alert error: #{e.message}"
        failure("Failed to send warning alert: #{e.message}")
      end
    end

    def send_info_notification(alert_type, data = {})
      begin
        alert = create_admin_alert(alert_type, 'info', data)
        
        # Info notifications typically just go to in-app
        in_app_result = create_in_app_notification(alert, data)
        
        success(
          message: "Info notification sent successfully",
          alert: serialize_alert(alert),
          notification_sent: in_app_result[:success],
          alert_id: alert.id
        )
      rescue => e
        Rails.logger.error "Info notification error: #{e.message}"
        failure("Failed to send info notification: #{e.message}")
      end
    end

    def send_business_alert(alert_type, data = {})
      begin
        # Business alerts for things like revenue milestones, churn alerts, etc.
        priority = determine_business_alert_priority(alert_type, data)
        alert = create_admin_alert(alert_type, priority, data)
        
        notifications_sent = []
        
        # Business alerts usually go to specific stakeholders
        stakeholders = get_business_alert_stakeholders(alert_type)
        
        stakeholders.each do |stakeholder|
          if stakeholder[:notification_type] == 'email'
            email_result = send_stakeholder_email(alert, data, stakeholder)
            notifications_sent << { 
              type: 'email', 
              recipient: stakeholder[:email], 
              success: email_result[:success] 
            }
          end
        end
        
        # Always create in-app notification
        in_app_result = create_in_app_notification(alert, data)
        notifications_sent << { type: 'in_app', success: in_app_result[:success] }
        
        success(
          message: "Business alert sent successfully",
          alert: serialize_alert(alert),
          notifications_sent: notifications_sent,
          stakeholders_notified: stakeholders.count
        )
      rescue => e
        Rails.logger.error "Business alert error: #{e.message}"
        failure("Failed to send business alert: #{e.message}")
      end
    end

    def send_system_health_alert(health_data)
      begin
        # Determine alert level based on health data
        alert_level = determine_health_alert_level(health_data)
        return success(message: "System healthy - no alert needed") if alert_level == 'healthy'
        
        alert_type = "system_health_#{alert_level}"
        alert = create_admin_alert(alert_type, alert_level, health_data)
        
        notifications_sent = []
        
        case alert_level
        when 'critical'
          # Critical system issues need immediate attention
          notifications_sent += send_immediate_system_alerts(alert, health_data)
        when 'warning'
          # Warning level - email and in-app
          email_result = send_email_alert(alert, health_data)
          notifications_sent << { type: 'email', success: email_result[:success] }
        end
        
        # Always create in-app notification for system health
        in_app_result = create_in_app_notification(alert, health_data)
        notifications_sent << { type: 'in_app', success: in_app_result[:success] }
        
        success(
          message: "System health alert sent",
          alert_level: alert_level,
          alert: serialize_alert(alert),
          notifications_sent: notifications_sent
        )
      rescue => e
        Rails.logger.error "System health alert error: #{e.message}"
        failure("Failed to send system health alert: #{e.message}")
      end
    end

    def send_user_milestone_notification(milestone_type, data = {})
      begin
        # Positive notifications for business milestones
        alert = create_admin_alert("milestone_#{milestone_type}", 'info', data)
        
        # These are typically celebratory, so different notification style
        notifications_sent = []
        
        # Send to team channels/email lists
        if milestone_type == 'revenue' && data[:amount] && data[:amount] >= 10000
          team_result = send_team_celebration_notification(alert, data)
          notifications_sent << { type: 'team_notification', success: team_result[:success] }
        end
        
        in_app_result = create_in_app_notification(alert, data)
        notifications_sent << { type: 'in_app', success: in_app_result[:success] }
        
        success(
          message: "Milestone notification sent",
          milestone: milestone_type,
          alert: serialize_alert(alert),
          notifications_sent: notifications_sent
        )
      rescue => e
        Rails.logger.error "Milestone notification error: #{e.message}"
        failure("Failed to send milestone notification: #{e.message}")
      end
    end

    def get_active_alerts(filter_params = {})
      begin
        alerts = AdminAlert.active
        
        # Apply filters
        alerts = alerts.where(priority: filter_params[:priority]) if filter_params[:priority].present?
        alerts = alerts.where(alert_type: filter_params[:alert_type]) if filter_params[:alert_type].present?
        alerts = alerts.where(created_at: filter_params[:created_after]..) if filter_params[:created_after].present?
        
        # Sort by priority and recency
        alerts = alerts.order(:priority, created_at: :desc)
        
        success(
          alerts: alerts.map { |alert| serialize_alert(alert) },
          total_count: alerts.count,
          by_priority: alerts.group(:priority).count
        )
      rescue => e
        Rails.logger.error "Get active alerts error: #{e.message}"
        failure("Failed to get active alerts: #{e.message}")
      end
    end

    def acknowledge_alert(alert_id, admin_user_id)
      begin
        alert = AdminAlert.find(alert_id)
        
        alert.update!(
          acknowledged: true,
          acknowledged_at: Time.current,
          acknowledged_by: admin_user_id
        )
        
        success(
          message: "Alert acknowledged",
          alert: serialize_alert(alert)
        )
      rescue ActiveRecord::RecordNotFound
        failure("Alert not found")
      rescue => e
        Rails.logger.error "Acknowledge alert error: #{e.message}"
        failure("Failed to acknowledge alert: #{e.message}")
      end
    end

    def resolve_alert(alert_id, admin_user_id, resolution_notes = nil)
      begin
        alert = AdminAlert.find(alert_id)
        
        alert.update!(
          status: 'resolved',
          resolved_at: Time.current,
          resolved_by: admin_user_id,
          resolution_notes: resolution_notes
        )
        
        success(
          message: "Alert resolved",
          alert: serialize_alert(alert)
        )
      rescue ActiveRecord::RecordNotFound
        failure("Alert not found")
      rescue => e
        Rails.logger.error "Resolve alert error: #{e.message}"
        failure("Failed to resolve alert: #{e.message}")
      end
    end

    private

    # ===== ALERT CREATION =====
    
    def create_admin_alert(alert_type, priority, data)
      # This would create an AdminAlert record
      # For now, return a mock object
      OpenStruct.new(
        id: SecureRandom.uuid,
        alert_type: alert_type,
        priority: priority,
        data: data,
        status: 'active',
        created_at: Time.current,
        acknowledged: false,
        acknowledged_at: nil,
        acknowledged_by: nil,
        resolved_at: nil,
        resolved_by: nil,
        resolution_notes: nil
      )
    end

    # ===== NOTIFICATION ROUTING =====
    
    def should_send_email_alert?(alert_type, priority)
      # Business logic for when to send email alerts
      case priority
      when 'critical'
        true
      when 'warning'
        ['payment_failure', 'system_health', 'security'].include?(alert_type)
      when 'info'
        false
      else
        false
      end
    end

    def should_send_slack_alert?(alert_type, priority)
      # Only send Slack for critical system issues
      priority == 'critical' && ['system_health', 'security', 'payment_processor'].include?(alert_type)
    end

    def should_send_sms_alert?(alert_type, priority)
      # SMS only for the most critical issues
      priority == 'critical' && ['system_down', 'security_breach', 'payment_processor_down'].include?(alert_type)
    end

    # ===== NOTIFICATION SENDING =====
    
    def send_email_alert(alert, data)
      begin
        # This would integrate with your email service
        # Using existing EmailManagement services where possible
        
        subject = build_alert_email_subject(alert)
        body = build_alert_email_body(alert, data)
        recipients = get_admin_email_recipients(alert.alert_type, alert.priority)
        
        # Use your existing email service
        Rails.logger.info "Sending email alert: #{subject} to #{recipients.join(', ')}"
        
        success(message: "Email alert sent successfully")
      rescue => e
        Rails.logger.error "Email alert error: #{e.message}"
        failure("Failed to send email alert: #{e.message}")
      end
    end

    def send_slack_alert(alert, data)
      begin
        # This would integrate with Slack API
        message = build_slack_alert_message(alert, data)
        channel = get_slack_alert_channel(alert.alert_type)
        
        Rails.logger.info "Sending Slack alert to #{channel}: #{message}"
        
        success(message: "Slack alert sent successfully")
      rescue => e
        Rails.logger.error "Slack alert error: #{e.message}"
        failure("Failed to send Slack alert: #{e.message}")
      end
    end

    def send_sms_alert(alert, data)
      begin
        # This would integrate with SMS service (Twilio, etc.)
        message = build_sms_alert_message(alert, data)
        recipients = get_admin_sms_recipients(alert.alert_type)
        
        Rails.logger.info "Sending SMS alert: #{message} to #{recipients.join(', ')}"
        
        success(message: "SMS alert sent successfully")
      rescue => e
        Rails.logger.error "SMS alert error: #{e.message}"
        failure("Failed to send SMS alert: #{e.message}")
      end
    end

    def create_in_app_notification(alert, data)
      begin
        # This would create in-app notifications for admin users
        Rails.logger.info "Creating in-app notification for alert: #{alert.alert_type}"
        
        success(message: "In-app notification created successfully")
      rescue => e
        Rails.logger.error "In-app notification error: #{e.message}"
        failure("Failed to create in-app notification: #{e.message}")
      end
    end

    def send_stakeholder_email(alert, data, stakeholder)
      begin
        # Send customized email to specific stakeholder
        Rails.logger.info "Sending stakeholder email to #{stakeholder[:email]}"
        
        success(message: "Stakeholder email sent successfully")
      rescue => e
        failure("Failed to send stakeholder email: #{e.message}")
      end
    end

    def send_immediate_system_alerts(alert, health_data)
      notifications = []
      
      # Email to on-call team
      email_result = send_email_alert(alert, health_data)
      notifications << { type: 'email', success: email_result[:success] }
      
      # Slack to emergency channel
      slack_result = send_slack_alert(alert, health_data)
      notifications << { type: 'slack', success: slack_result[:success] }
      
      # SMS to on-call engineer if configured
      if get_on_call_phone_number
        sms_result = send_sms_alert(alert, health_data)
        notifications << { type: 'sms', success: sms_result[:success] }
      end
      
      notifications
    end

    def send_team_celebration_notification(alert, data)
      begin
        # Send positive milestone notifications to team
        Rails.logger.info "Sending team celebration for milestone: #{data}"
        
        success(message: "Team celebration notification sent")
      rescue => e
        failure("Failed to send team celebration: #{e.message}")
      end
    end

    # ===== BUSINESS LOGIC =====
    
    def determine_business_alert_priority(alert_type, data)
      case alert_type
      when 'revenue_milestone'
        data[:amount] >= 100000 ? 'critical' : 'info'
      when 'churn_spike'
        data[:churn_rate] >= 10 ? 'critical' : 'warning'
      when 'payment_failure_spike'
        data[:failure_count] >= 20 ? 'critical' : 'warning'
      else
        'info'
      end
    end

    def get_business_alert_stakeholders(alert_type)
      # Return stakeholders who should be notified for different business alerts
      case alert_type
      when 'revenue_milestone', 'churn_spike'
        [
          { email: 'ceo@xspacegrow.com', notification_type: 'email' },
          { email: 'cto@xspacegrow.com', notification_type: 'email' }
        ]
      when 'payment_failure_spike'
        [
          { email: 'finance@xspacegrow.com', notification_type: 'email' },
          { email: 'support@xspacegrow.com', notification_type: 'email' }
        ]
      else
        []
      end
    end

    def determine_health_alert_level(health_data)
      # Analyze health data to determine alert level
      overall_status = health_data[:overall_status]
      
      case overall_status
      when 'critical'
        'critical'
      when 'warning'
        'warning'
      when 'degraded'
        'warning'
      else
        'healthy'
      end
    end

    # ===== MESSAGE BUILDING =====
    
    def build_alert_email_subject(alert)
      priority_prefix = alert.priority.upcase
      alert_type_readable = alert.alert_type.humanize.titlecase
      
      "[#{priority_prefix}] XSpaceGrow Alert: #{alert_type_readable}"
    end

    def build_alert_email_body(alert, data)
      body = "Alert Details:\n"
      body += "Type: #{alert.alert_type.humanize}\n"
      body += "Priority: #{alert.priority.upcase}\n"
      body += "Time: #{alert.created_at}\n\n"
      
      body += "Data:\n"
      data.each do |key, value|
        body += "#{key.to_s.humanize}: #{value}\n"
      end
      
      body += "\n\nPlease investigate immediately if this is a critical alert."
      body
    end

    def build_slack_alert_message(alert, data)
      emoji = case alert.priority
              when 'critical' then '🚨'
              when 'warning' then '⚠️'
              else 'ℹ️'
              end
      
      "#{emoji} *#{alert.priority.upcase}*: #{alert.alert_type.humanize} - #{data[:message] || 'Alert triggered'}"
    end

    def build_sms_alert_message(alert, data)
      "XSpaceGrow CRITICAL: #{alert.alert_type.humanize} - #{data[:message] || 'Immediate attention required'}"
    end

    # ===== CONFIGURATION =====
    
    def get_admin_email_recipients(alert_type, priority)
      # Return list of admin emails based on alert type and priority
      case priority
      when 'critical'
        ['admin@xspacegrow.com', 'cto@xspacegrow.com', 'oncall@xspacegrow.com']
      when 'warning'
        ['admin@xspacegrow.com', 'support@xspacegrow.com']
      else
        ['admin@xspacegrow.com']
      end
    end

    def get_slack_alert_channel(alert_type)
      case alert_type
      when /system_health/
        '#alerts-system'
      when /payment/
        '#alerts-business'
      when /security/
        '#alerts-security'
      else
        '#alerts-general'
      end
    end

    def get_admin_sms_recipients(alert_type)
      # Return phone numbers for SMS alerts
      ['+1234567890'] # Placeholder
    end

    def get_on_call_phone_number
      # Return on-call engineer phone number
      '+1234567890' # Placeholder
    end

    # ===== SERIALIZATION =====
    
    def serialize_alert(alert)
      {
        id: alert.id,
        alert_type: alert.alert_type,
        priority: alert.priority,
        status: alert.status,
        data: alert.data,
        created_at: alert.created_at,
        acknowledged: alert.acknowledged,
        acknowledged_at: alert.acknowledged_at,
        acknowledged_by: alert.acknowledged_by,
        resolved_at: alert.resolved_at,
        resolved_by: alert.resolved_by,
        resolution_notes: alert.resolution_notes
      }
    end
  end
end