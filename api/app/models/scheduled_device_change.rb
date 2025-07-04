# app/models/scheduled_device_change.rb
class ScheduledDeviceChange < ApplicationRecord
  belongs_to :user
  
  validates :status, inclusion: { in: %w[pending completed failed canceled] }
  validates :action, inclusion: { in: %w[disable enable] }
  validates :scheduled_for, presence: true
  validates :device_ids, presence: true
  
  scope :pending, -> { where(status: 'pending') }
  scope :due, -> { where('scheduled_for <= ?', Time.current) }
  
  def execute!
    return false unless pending?
    
    ActiveRecord::Base.transaction do
      case action
      when 'disable'
        DeviceManagementService.disable_devices(device_ids, reason: reason)
      when 'enable'
        DeviceManagementService.enable_devices(device_ids)
      end
      
      update!(status: 'completed', executed_at: Time.current)
      true
    end
  rescue => e
    update!(status: 'failed', error_message: e.message)
    false
  end
end