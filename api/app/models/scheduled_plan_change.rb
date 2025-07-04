# app/models/scheduled_plan_change.rb
class ScheduledPlanChange < ApplicationRecord
  belongs_to :subscription
  belongs_to :target_plan, class_name: 'Plan'
  
  validates :status, inclusion: { in: %w[pending completed failed canceled] }
  validates :target_interval, inclusion: { in: %w[month year] }
  validates :scheduled_for, presence: true
  
  scope :pending, -> { where(status: 'pending') }
  scope :due, -> { where('scheduled_for <= ?', Time.current) }
  scope :overdue, -> { pending.where('scheduled_for < ?', Time.current) }
  
  def pending?
    status == 'pending'
  end
  
  def due?
    pending? && scheduled_for <= Time.current
  end
  
  def execute!
    return false unless pending?
    return false if scheduled_for > Time.current
    
    ActiveRecord::Base.transaction do
      # Update the subscription directly
      subscription.update!(
        plan: target_plan,
        interval: target_interval
      )
      
      # Mark as completed
      update!(
        status: 'completed',
        executed_at: Time.current
      )
      
      Rails.logger.info "Executed scheduled plan change #{id}: #{subscription.user.email} to #{target_plan.name}"
      true
    end
  rescue => e
    update!(
      status: 'failed',
      error_message: e.message,
      executed_at: Time.current
    )
    Rails.logger.error "Failed to execute scheduled plan change #{id}: #{e.message}"
    false
  end
  
  def cancel!
    return false unless pending?
    
    update!(
      status: 'canceled',
      canceled_at: Time.current
    )
    
    true
  end
  
  # Class method to process all due changes
  def self.process_due_changes
    processed = 0
    failed = 0
    
    due.find_each do |change|
      if change.execute!
        processed += 1
      else
        failed += 1
      end
    end
    
    Rails.logger.info "Processed scheduled plan changes: #{processed} successful, #{failed} failed"
    { processed: processed, failed: failed }
  end
end