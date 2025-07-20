# app/services/admin/dashboard_service.rb
module Admin
  class DashboardService < ApplicationService
    def initialize(period = 'week')
      @period = period
      @date_range = calculate_date_range(period)
    end

    def call
      begin
        success(
          summary: build_summary_stats,
          recent_activity: build_recent_activity,
          alerts: build_system_alerts,
          quick_stats: build_quick_stats,
          period: @period,
          last_updated: Time.current.iso8601
        )
      rescue => e
        Rails.logger.error "Dashboard service error: #{e.message}"
        failure("Failed to load dashboard data: #{e.message}")
      end
    end

    private

    attr_reader :period, :date_range

    def build_summary_stats
      {
        users: {
          total: User.count,
          new_this_period: User.where(created_at: @date_range).count,
          active_subscriptions: Subscription.where(status: 'active').count,
          vip_users: User.where(role: 'vip').count
        },
        devices: {
          total: Device.count,
          active: Device.where(status: 'active').count,
          offline: Device.where(status: 'offline').count,
          error: Device.where(status: 'error').count,
          new_this_period: Device.where(created_at: @date_range).count
        },
        revenue: {
          mrr: calculate_monthly_recurring_revenue,
          total_revenue_this_period: calculate_period_revenue,
          average_revenue_per_user: calculate_arpu,
          past_due_amount: calculate_past_due_amount
        },
        subscriptions: {
          active: Subscription.where(status: 'active').count,
          past_due: Subscription.where(status: 'past_due').count,
          canceled: Subscription.where(status: 'canceled').count,
          new_this_period: Subscription.where(created_at: @date_range).count
        }
      }
    end

    def build_recent_activity
      {
        new_users: User.where(created_at: 24.hours.ago..)
                      .limit(5)
                      .pluck(:id, :email, :display_name, :created_at)
                      .map { |id, email, name, created| 
                        { id: id, email: email, name: name, created_at: created.iso8601 } 
                      },
        
        new_devices: Device.where(created_at: 24.hours.ago..)
                          .includes(:user)
                          .limit(5)
                          .map { |device|
                            {
                              id: device.id,
                              name: device.name,
                              user_email: device.user.email,
                              status: device.status,
                              created_at: device.created_at.iso8601
                            }
                          },
        
        recent_orders: Order.where(created_at: 24.hours.ago..)
                           .includes(:user)
                           .limit(5)
                           .map { |order|
                             {
                               id: order.id,
                               user_email: order.user.email,
                               total: order.total,
                               status: order.status,
                               created_at: order.created_at.iso8601
                             }
                           },
        
        device_alerts: Device.where(status: 'error', updated_at: 24.hours.ago..)
                            .includes(:user)
                            .limit(5)
                            .map { |device|
                              {
                                id: device.id,
                                name: device.name,
                                user_email: device.user.email,
                                issue: device.last_error || 'Connection error',
                                updated_at: device.updated_at.iso8601
                              }
                            }
      }
    end

    def build_system_alerts
      alerts = []

      # Check for devices with errors
      error_device_count = Device.where(status: 'error').count
      if error_device_count > 0
        alerts << {
          type: 'warning',
          title: 'Device Errors',
          message: "#{error_device_count} device(s) reporting errors",
          count: error_device_count,
          action_url: '/admin/devices?status=error'
        }
      end

      # Check for past due subscriptions
      past_due_count = Subscription.where(status: 'past_due').count
      if past_due_count > 0
        alerts << {
          type: 'danger',
          title: 'Past Due Subscriptions',
          message: "#{past_due_count} subscription(s) past due",
          count: past_due_count,
          action_url: '/admin/subscriptions?status=past_due'
        }
      end

      # Check for offline devices (more than 1 hour)
      offline_device_count = Device.where(
        status: 'offline',
        last_connection: ..1.hour.ago
      ).count
      
      if offline_device_count > 10 # Only alert if significant number
        alerts << {
          type: 'info',
          title: 'Offline Devices',
          message: "#{offline_device_count} device(s) offline for over 1 hour",
          count: offline_device_count,
          action_url: '/admin/devices?status=offline'
        }
      end

      # Check for failed payments in last 24 hours
      failed_payments = Order.where(
        status: 'payment_failed',
        created_at: 24.hours.ago..
      ).count
      
      if failed_payments > 0
        alerts << {
          type: 'warning',
          title: 'Payment Failures',
          message: "#{failed_payments} payment failure(s) in last 24 hours",
          count: failed_payments,
          action_url: '/admin/orders?status=payment_failed'
        }
      end

      alerts
    end

    def build_quick_stats
      {
        device_utilization: calculate_device_utilization_percentage,
        system_uptime: calculate_system_uptime_percentage,
        growth_rate: calculate_user_growth_rate,
        revenue_trend: calculate_revenue_trend,
        top_device_types: get_top_device_types,
        plan_distribution: get_plan_distribution
      }
    end

    # Calculation methods with real data
    def calculate_monthly_recurring_revenue
      # Sum up all active subscription plan prices
      plan_mrr = Subscription.active
                           .joins(:plan)
                           .sum('plans.monthly_price')
      
      # Add extra device slot costs
      extra_mrr = ExtraDeviceSlot.joins(subscription: :user)
                                .where(subscriptions: { status: 'active' })
                                .sum(:monthly_cost)
      
      plan_mrr + extra_mrr
    end

    def calculate_period_revenue
      Order.where(
        status: 'completed',
        created_at: @date_range
      ).sum(:total)
    end

    def calculate_arpu
      active_subscriptions = Subscription.where(status: 'active').count
      return 0 if active_subscriptions.zero?
      
      (calculate_monthly_recurring_revenue.to_f / active_subscriptions).round(2)
    end

    def calculate_past_due_amount
      Subscription.where(status: 'past_due')
                 .joins(:plan)
                 .sum('plans.monthly_price')
    end

    def calculate_device_utilization_percentage
      total_capacity = Subscription.active
                                 .joins(:plan)
                                 .sum('plans.device_limit')
      
      return 0 if total_capacity.zero?
      
      active_devices = Device.where(status: 'active').count
      (active_devices.to_f / total_capacity * 100).round(1)
    end

    def calculate_system_uptime_percentage
      # Simple calculation based on device connectivity
      total_devices = Device.count
      return 100 if total_devices.zero?
      
      connected_devices = Device.where.not(status: 'error').count
      (connected_devices.to_f / total_devices * 100).round(1)
    end

    def calculate_user_growth_rate
      current_period_users = User.where(created_at: @date_range).count
      previous_period_users = User.where(
        created_at: calculate_previous_period_range
      ).count
      
      return 0 if previous_period_users.zero?
      
      growth = ((current_period_users - previous_period_users).to_f / previous_period_users * 100)
      growth.round(1)
    end

    def calculate_revenue_trend
      current_revenue = calculate_period_revenue
      previous_revenue = Order.where(
        status: 'completed',
        created_at: calculate_previous_period_range
      ).sum(:total)
      
      return 0 if previous_revenue.zero?
      
      trend = ((current_revenue - previous_revenue).to_f / previous_revenue * 100)
      trend.round(1)
    end

    def get_top_device_types
      Device.joins(:device_type)
            .group('device_types.name')
            .order('COUNT(*) DESC')
            .limit(5)
            .count
    end

    def get_plan_distribution
      Subscription.active
                 .joins(:plan)
                 .group('plans.name')
                 .count
    end

    def calculate_date_range(period)
      case period
      when 'today'
        Date.current.all_day
      when 'week'
        1.week.ago..Time.current
      when 'month'
        1.month.ago..Time.current
      when 'quarter'
        3.months.ago..Time.current
      else
        1.week.ago..Time.current
      end
    end

    def calculate_previous_period_range
      duration = @date_range.end - @date_range.begin
      (@date_range.begin - duration)..@date_range.begin
    end
  end
end