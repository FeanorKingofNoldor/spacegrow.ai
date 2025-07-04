# app/jobs/scheduled_plan_change_job.rb
class ScheduledPlanChangeJob < ApplicationJob
  queue_as :default
  
  def perform(subscription_id, target_plan_id, target_interval)
    subscription = Subscription.find_by(id: subscription_id)
    target_plan = Plan.find_by(id: target_plan_id)
    
    unless subscription && target_plan
      Rails.logger.error "ScheduledPlanChangeJob: Invalid subscription (#{subscription_id}) or plan (#{target_plan_id})"
      return
    end
    
    # Find the scheduled change record
    scheduled_change = subscription.scheduled_plan_changes
                                  .pending
                                  .find_by(target_plan: target_plan, target_interval: target_interval)
    
    if scheduled_change
      success = scheduled_change.execute!
      
      if success
        Rails.logger.info "Successfully executed scheduled plan change for subscription #{subscription_id}"
        
        # Send notification email
        UserMailer.plan_change_executed(subscription.user, scheduled_change).deliver_now
      else
        Rails.logger.error "Failed to execute scheduled plan change for subscription #{subscription_id}"
        
        # Send failure notification
        UserMailer.plan_change_failed(subscription.user, scheduled_change).deliver_now
      end
    else
      Rails.logger.warn "No pending scheduled plan change found for subscription #{subscription_id}"
    end
  end
end

# app/jobs/scheduled_device_change_job.rb
class ScheduledDeviceChangeJob < ApplicationJob
  queue_as :default
  
  def perform(scheduled_change_id)
    scheduled_change = ScheduledDeviceChange.find_by(id: scheduled_change_id)
    
    unless scheduled_change
      Rails.logger.error "ScheduledDeviceChangeJob: Invalid scheduled change (#{scheduled_change_id})"
      return
    end
    
    success = scheduled_change.execute!
    
    if success
      Rails.logger.info "Successfully executed scheduled device change #{scheduled_change_id}"
      
      # Send notification email
      UserMailer.device_change_executed(scheduled_change.user, scheduled_change).deliver_now
    else
      Rails.logger.error "Failed to execute scheduled device change #{scheduled_change_id}"
      
      # Send failure notification  
      UserMailer.device_change_failed(scheduled_change.user, scheduled_change).deliver_now
    end
  end
end

# app/jobs/cleanup_expired_scheduled_changes_job.rb
class CleanupExpiredScheduledChangesJob < ApplicationJob
  queue_as :low_priority
  
  # Run this job daily to clean up old scheduled changes
  def perform
    # Clean up completed/failed scheduled plan changes older than 30 days
    ScheduledPlanChange.where(status: ['completed', 'failed', 'canceled'])
                       .where('updated_at < ?', 30.days.ago)
                       .destroy_all
    
    # Clean up completed/failed device changes older than 30 days  
    ScheduledDeviceChange.where(status: ['completed', 'failed', 'canceled'])
                         .where('updated_at < ?', 30.days.ago)
                         .destroy_all
    
    Rails.logger.info "Cleaned up expired scheduled changes"
  end
end

# app/jobs/send_plan_change_reminders_job.rb
class SendPlanChangeRemindersJob < ApplicationJob
  queue_as :default
  
  # Run this job daily to send reminders about upcoming plan changes
  def perform
    # Send 7-day reminders
    seven_day_changes = ScheduledPlanChange.pending
                                          .where(scheduled_for: 7.days.from_now.beginning_of_day..7.days.from_now.end_of_day)
                                          .includes(:subscription, :target_plan)
    
    seven_day_changes.each do |change|
      UserMailer.plan_change_reminder_7_days(change.subscription.user, change).deliver_now
    end
    
    # Send 1-day reminders  
    one_day_changes = ScheduledPlanChange.pending
                                        .where(scheduled_for: 1.day.from_now.beginning_of_day..1.day.from_now.end_of_day)
                                        .includes(:subscription, :target_plan)
    
    one_day_changes.each do |change|
      UserMailer.plan_change_reminder_1_day(change.subscription.user, change).deliver_now
    end
    
    Rails.logger.info "Sent #{seven_day_changes.count} 7-day and #{one_day_changes.count} 1-day plan change reminders"
  end
end