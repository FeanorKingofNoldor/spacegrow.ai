module SubscriptionManagement
  class PlanChangeAnalyzer < ApplicationService
    include ActiveModel::Model
    
    attr_accessor :user, :current_plan, :target_plan, :target_interval
    
    def initialize(user:, target_plan:, target_interval: 'month')
      @user = user
      @current_plan = user.subscription&.plan
      @target_plan = target_plan
      @target_interval = target_interval
      
      # 🔥 FIX: Cache device count to prevent N+1 queries
      @active_device_count = user.devices.active.count
    end
    
    def analyze
      {
        change_type: determine_change_type,
        current_plan: current_plan_data,
        target_plan: target_plan_data,
        device_impact: device_impact_analysis,
        billing_impact: billing_impact_analysis,
        warnings: generate_warnings,
        available_strategies: available_strategies
      }
    end
    
    private
    
    # 🔥 FIX: Use cached count instead of querying repeatedly
    def active_device_count
      @active_device_count
    end
    
    def determine_change_type
      return 'new_subscription' unless current_plan
      return 'current' if same_plan_and_interval?
      return 'upgrade' if target_plan.device_limit > current_plan.device_limit
      return 'downgrade_safe' if active_device_count <= target_plan.device_limit
      return 'downgrade_warning' # Devices exceed new limit
    end
    
    def same_plan_and_interval?
      current_plan == target_plan && user.subscription.interval == target_interval
    end
    
    def current_plan_data
      return nil unless current_plan
      
      {
        id: current_plan.id,
        name: current_plan.name,
        device_limit: current_plan.device_limit,
        monthly_price: current_plan.monthly_price,
        yearly_price: current_plan.yearly_price,
        current_interval: user.subscription.interval,
        devices_used: active_device_count, # 🔥 FIX: Use cached count
        additional_device_slots: user.subscription.additional_device_slots
      }
    end
    
    def target_plan_data
      {
        id: target_plan.id,
        name: target_plan.name,
        device_limit: target_plan.device_limit,
        monthly_price: target_plan.monthly_price,
        yearly_price: target_plan.yearly_price,
        target_interval: target_interval
      }
    end
    
    def device_impact_analysis
      current_device_count = active_device_count # 🔥 FIX: Use cached count
      target_device_limit = target_plan.device_limit
      device_difference = target_device_limit - current_device_count
      excess_count = [device_difference * -1, 0].max
      
      {
        current_device_count: current_device_count,
        target_device_limit: target_device_limit,
        device_difference: device_difference,
        requires_device_selection: device_difference < 0,
        excess_device_count: excess_count,
        affected_devices: excess_count > 0 ? get_affected_devices(excess_count) : []
      }
    end
    
    def billing_impact_analysis
      current_cost = current_plan ? calculate_current_monthly_cost : 0
      target_cost = target_interval == 'month' ? target_plan.monthly_price : target_plan.yearly_price / 12
      
      {
        current_monthly_cost: current_cost,
        target_monthly_cost: target_cost,
        cost_difference: target_cost - current_cost,
        no_refund_policy: true,
        extra_device_cost_per_month: Plan::ADDITIONAL_DEVICE_COST,
        potential_extra_cost: calculate_potential_extra_cost
      }
    end
    
    def calculate_current_monthly_cost
      base_cost = user.subscription.interval == 'month' ? 
                  current_plan.monthly_price : 
                  current_plan.yearly_price / 12
      
      extra_device_cost = user.subscription.additional_device_slots * Plan::ADDITIONAL_DEVICE_COST
      base_cost + extra_device_cost
    end
    
    def calculate_potential_extra_cost
      # 🔥 FIX: Calculate excess count directly instead of calling device_impact_analysis
      current_device_count = active_device_count
      target_device_limit = target_plan.device_limit
      device_difference = target_device_limit - current_device_count
      excess_devices = [device_difference * -1, 0].max
      excess_devices * Plan::ADDITIONAL_DEVICE_COST
    end
    
    def get_affected_devices(excess_count)
      return [] if excess_count <= 0
      
      # Get devices that would be affected by downgrade
      # Prioritize: Offline devices first, then oldest devices
      devices = user.devices.active
                    .includes(:device_type)
                    .order(:created_at)
                    .to_a
      
      # Sort by priority in Ruby instead of SQL
      one_week_ago = 1.week.ago
      one_day_ago = 1.day.ago
      
      devices.sort_by! do |device|
        if device.last_connection.nil? || device.last_connection < one_week_ago
          [0, device.created_at] # Highest priority - offline for over a week
        elsif device.last_connection < one_day_ago
          [1, device.created_at] # Medium priority - offline for over a day
        else
          [2, device.created_at] # Lowest priority - recently active
        end
      end
      
      devices.first(excess_count).map { |device| device_selection_data(device) }
    end
    
    def device_selection_data(device)
      one_day_ago = 1.day.ago.utc
      
      {
        id: device.id,
        name: device.name,
        device_type: device.device_type.name,
        status: device.status,
        last_connection: device.last_connection,
        alert_status: device.alert_status,
        is_offline: device.last_connection.nil? || device.last_connection < one_day_ago,
      }
    end
      
    def generate_warnings
      warnings = []
      
      case determine_change_type
      when 'current'
        warnings << "You are already subscribed to the #{target_plan.name} plan with #{target_interval}ly billing."
      when 'downgrade_warning'
        # 🔥 FIX: Calculate excess count directly
        current_device_count = active_device_count
        target_device_limit = target_plan.device_limit
        device_difference = target_device_limit - current_device_count
        excess = [device_difference * -1, 0].max
        warnings << "Downgrading will exceed your device limit by #{excess} device#{'s' if excess > 1}."
        warnings << "You'll need to choose which devices to keep active or pay extra for additional slots."
      when 'downgrade_safe'
        warnings << "This downgrade will not affect your current devices since you're within the new limit."
      end
      
      warnings << "No refunds are provided for plan changes." if determine_change_type.include?('downgrade')
      
      warnings
    end
    
    def available_strategies
      strategies = []
      
      case determine_change_type
      when 'upgrade', 'new_subscription'
        strategies << {
          type: 'immediate',
          name: 'Upgrade Immediately',
          description: 'Get access to new features and device slots right away',
          recommended: true
        }
      when 'downgrade_safe'
        strategies += safe_downgrade_strategies
      when 'downgrade_warning'
        strategies += warning_downgrade_strategies
      when 'current'
        # No strategies needed for current plan
      end
      
      strategies
    end
    
    def safe_downgrade_strategies
      [
        {
          type: 'immediate',
          name: 'Downgrade Immediately',
          description: 'Switch to the new plan right away. Your devices will not be affected.',
          recommended: true
        },
        {
          type: 'end_of_period',
          name: 'Downgrade at Period End',
          description: "Wait until your current billing period ends (#{user.subscription.current_period_end&.strftime('%B %d, %Y')})",
          recommended: false
        }
      ]
    end
    
    def warning_downgrade_strategies
      # 🔥 FIX: Calculate excess count directly
      current_device_count = active_device_count
      target_device_limit = target_plan.device_limit
      device_difference = target_device_limit - current_device_count
      excess_count = [device_difference * -1, 0].max
      extra_cost = excess_count * Plan::ADDITIONAL_DEVICE_COST
      
      [
        {
          type: 'end_of_period',
          name: 'Schedule for Period End',
          description: "Keep all devices until #{user.subscription.current_period_end&.strftime('%B %d, %Y')}, then choose which to keep",
          recommended: true
        },
        {
          type: 'immediate_with_selection',
          name: 'Downgrade with Device Selection',
          description: "Choose which #{target_plan.device_limit} devices to keep active now",
          recommended: false
        },
        {
          type: 'pay_for_extra',
          name: 'Keep All Devices',
          description: "Downgrade plan but pay $#{extra_cost}/month extra for #{excess_count} additional device#{'s' if excess_count > 1}",
          recommended: false,
          extra_monthly_cost: extra_cost
        }
      ]
    end
  end
end