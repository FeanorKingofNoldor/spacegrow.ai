# app/jobs/admin/system_cleanup_job.rb
module Admin
  class SystemCleanupJob < ApplicationJob
    queue_as :admin_maintenance

    def perform
      Rails.logger.info "🔄 [SystemCleanupJob] Starting system maintenance and cleanup"
      
      begin
        cleanup_results = {
          expired_sessions: cleanup_expired_sessions,
          old_logs: cleanup_old_logs,
          stale_cache: cleanup_stale_cache,
          temporary_files: cleanup_temporary_files,
          old_alerts: cleanup_old_alerts
        }
        
        # Log cleanup results
        log_cleanup_results(cleanup_results)
        
        # Send summary if significant cleanup occurred
        send_cleanup_summary_if_needed(cleanup_results)
        
        Rails.logger.info "✅ [SystemCleanupJob] System cleanup completed successfully"
      rescue => e
        Rails.logger.error "❌ [SystemCleanupJob] Error during system cleanup: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        # Alert admins about cleanup failure
        notification_service = Admin::AdminNotificationService.new
        notification_service.send_warning_alert('system_cleanup_failed', {
          error: e.message,
          message: "System cleanup job failed"
        })
      end
    end

    private

    def cleanup_expired_sessions
      # Clean up expired user sessions
      expired_count = UserSession.where(expires_at: ..Time.current).count
      UserSession.where(expires_at: ..Time.current).destroy_all
      
      Rails.logger.info "🧹 [SystemCleanupJob] Cleaned up #{expired_count} expired sessions"
      expired_count
    end

    def cleanup_old_logs
      # Clean up old log entries (if you have a logs table)
      # This is a placeholder - implement based on your logging system
      cleaned_logs = 0
      
      Rails.logger.info "🧹 [SystemCleanupJob] Log cleanup completed - #{cleaned_logs} entries removed"
      cleaned_logs
    end

    def cleanup_stale_cache
      # Clean up stale cache entries
      cache_keys_pattern = "admin:*"
      cleaned_cache_keys = 0
      
      # This would depend on your cache implementation
      # For Redis: scan and delete old keys
      # For MemoryStore: Rails.cache.cleanup
      
      Rails.logger.info "🧹 [SystemCleanupJob] Cache cleanup completed - #{cleaned_cache_keys} keys cleaned"
      cleaned_cache_keys
    end

    def cleanup_temporary_files
      # Clean up temporary files
      temp_dir = Rails.root.join('tmp', 'uploads')
      cleaned_files = 0
      
      if Dir.exist?(temp_dir)
        Dir.glob(File.join(temp_dir, '*')).each do |file|
          if File.mtime(file) < 24.hours.ago
            File.delete(file)
            cleaned_files += 1
          end
        end
      end
      
      Rails.logger.info "🧹 [SystemCleanupJob] Cleaned up #{cleaned_files} temporary files"
      cleaned_files
    end

    def cleanup_old_alerts
      # Clean up old resolved alerts (keep for 30 days)
      old_alerts_count = 0
      
      # This would clean up AdminAlert records if you implement that model
      # old_alerts = AdminAlert.where(status: 'resolved', resolved_at: ..30.days.ago)
      # old_alerts_count = old_alerts.count
      # old_alerts.destroy_all
      
      Rails.logger.info "🧹 [SystemCleanupJob] Cleaned up #{old_alerts_count} old alerts"
      old_alerts_count
    end

    def log_cleanup_results(results)
      total_cleaned = results.values.sum
      Rails.logger.info "🧹 [SystemCleanupJob] Cleanup Summary:"
      Rails.logger.info "  - Expired sessions: #{results[:expired_sessions]}"
      Rails.logger.info "  - Old logs: #{results[:old_logs]}"
      Rails.logger.info "  - Stale cache: #{results[:stale_cache]}"
      Rails.logger.info "  - Temporary files: #{results[:temporary_files]}"
      Rails.logger.info "  - Old alerts: #{results[:old_alerts]}"
      Rails.logger.info "  - Total items cleaned: #{total_cleaned}"
    end

    def send_cleanup_summary_if_needed(results)
      total_cleaned = results.values.sum
      
      # Send notification if significant cleanup occurred
      if total_cleaned > 1000
        notification_service = Admin::AdminNotificationService.new
        notification_service.send_info_notification('system_cleanup_summary', {
          total_cleaned: total_cleaned,
          expired_sessions: results[:expired_sessions],
          temporary_files: results[:temporary_files],
          message: "Large system cleanup completed - #{total_cleaned} items cleaned"
        })
      end
    end
  end
end