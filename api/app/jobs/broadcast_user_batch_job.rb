# app/jobs/broadcast_user_batch_job.rb
class BroadcastUserBatchJob < ApplicationJob
  queue_as :real_time_broadcasts
  
  def perform(user_id)
    Rails.logger.debug "🔄 [BroadcastUserBatchJob] Executing batch broadcast for user #{user_id}"
    
    RealTime::ThrottledBroadcaster.execute_user_broadcast(user_id)
  rescue => e
    Rails.logger.error "❌ [BroadcastUserBatchJob] Error broadcasting to user #{user_id}: #{e.message}"
    raise e
  end
end