# app/services/admin/dashboard_service.rb - SIMPLIFIED FOR STARTUP
module Admin
  class DashboardService < ApplicationService
    def call
      begin
        success(
          business: business_overview,
          devices: device_overview,
          system: system_overview,
          alerts: critical_alerts
        )
      rescue => e
        Rails.logger.error "Admin Dashboard error: #{e.message}"
        failure("Failed to load dashboard: #{e.message}")
      end
    end

    private

    def business_overview
      {
        users: {
          total: User.count,
          new_this_week: User.where(created_at: 1.week.ago..).count,
          active_subscriptions: active_subscriptions_count,
          past_due: past_due_subscriptions_count
        },
        revenue: {
          mrr: calculate_mrr,
          today: todays_revenue,
          this_week: this_weeks_revenue
        }
      }
    end

    def device_overview
      {
        total: Device.count,
        online: Device.where(status: 'active').count,
        offline: offline_devices_count,
        errors: Device.where(status: 'error').count,
        new_this_week: Device.where(created_at: 1.week.ago..).count
      }
    end

    def system_overview
      {
        database: simple_database_status,
        sidekiq: simple_sidekiq_status,
        last_checked: Time.current.iso8601
      }
    end

    def critical_alerts
      alerts = []
      
      # Critical device issues
      error_devices = Device.where(status: 'error').count
      if error_devices > 5
        alerts << {
          type: 'error',
          message: "#{error_devices} devices in error state",
          action: 'Check device fleet'
        }
      end

      # Offline devices
      offline_count = offline_devices_count
      if offline_count > 10
        alerts << {
          type: 'warning',
          message: "#{offline_count} devices offline >1 hour",
          action: 'Check connectivity'
        }
      end

      # Payment issues
      past_due_count = past_due_subscriptions_count
      if past_due_count > 3
        alerts << {
          type: 'warning',
          message: "#{past_due_count} users with past due payments",
          action: 'Review billing'
        }
      end

      # System issues
      queue_size = simple_sidekiq_queue_size
      if queue_size > 100
        alerts << {
          type: 'error',
          message: "Background job queue backed up (#{queue_size} jobs)",
          action: 'Check Sidekiq'
        }
      end

      alerts
    end

    # === SIMPLE CALCULATION METHODS ===

    def calculate_mrr
      if defined?(Subscription) && defined?(Plan)
        Subscription.joins(:plan).where(status: 'active').sum('plans.monthly_price').to_f
      else
        0.0
      end
    end

    def todays_revenue
      if defined?(Order)
        Order.where(created_at: Date.current.all_day, status: 'completed').sum(:total).to_f
      else
        0.0
      end
    end

    def this_weeks_revenue
      if defined?(Order)
        Order.where(created_at: 1.week.ago.., status: 'completed').sum(:total).to_f
      else
        0.0
      end
    end

    def active_subscriptions_count
      if defined?(Subscription)
        User.joins(:subscription).where(subscriptions: { status: 'active' }).count
      else
        0
      end
    end

    def past_due_subscriptions_count
      if defined?(Subscription)
        User.joins(:subscription).where(subscriptions: { status: 'past_due' }).count
      else
        0
      end
    end

    def offline_devices_count
      Device.where(last_connection: ..1.hour.ago).or(Device.where(last_connection: nil)).count
    end

    # === SIMPLE SYSTEM CHECKS ===

    def simple_database_status
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        'healthy'
      rescue
        'error'
      end
    end

    def simple_sidekiq_status
      begin
        require 'sidekiq/api'
        queue_size = Sidekiq::Queue.new.size
        queue_size > 100 ? 'warning' : 'healthy'
      rescue
        'error'
      end
    end

    def simple_sidekiq_queue_size
      begin
        require 'sidekiq/api'
        Sidekiq::Queue.new.size
      rescue
        0
      end
    end
  end
end