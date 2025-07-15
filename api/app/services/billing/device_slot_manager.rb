# app/services/billing/device_slot_manager.rb
module Billing
  class DeviceSlotManager < ApplicationService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # ===== CORE SLOT CALCULATIONS =====
    
    def base_slots
      @base_slots ||= calculate_base_slots
    end

    def purchased_extra_slots
      @purchased_extra_slots ||= user.subscription&.extra_device_slots&.active&.count || 0
    end

    def total_slots
      return Float::INFINITY if user.admin?
      base_slots + purchased_extra_slots
    end

    def used_slots
      @used_slots ||= user.devices.operational.count
    end

    def available_slots
      return Float::INFINITY if user.admin?
      [total_slots - used_slots, 0].max
    end

    # ===== STATE QUERIES =====
    
    def at_limit?
      return false if user.admin?
      used_slots >= total_slots
    end

    def over_limit?
      return false if user.admin?
      used_slots > total_slots
    end

    def can_activate_device?
      return true if user.admin?
      available_slots > 0
    end

    def over_limit_count
      return 0 if user.admin?
      [used_slots - total_slots, 0].max
    end

    # ===== BUSINESS LOGIC QUERIES =====

    def can_buy_extra_slot?
      # Always true - never block someone from paying us money!
      true
    end

    def would_be_over_limit_if_slot_removed?
      return false if user.admin?
      return false if purchased_extra_slots == 0
      
      # If we removed one slot, would we be over limit?
      (total_slots - 1) < used_slots
    end

    def slots_needed_for_devices(device_count)
      return 0 if user.admin?
      needed = device_count - total_slots
      [needed, 0].max
    end

    # ===== SUMMARY DATA =====

    def slot_summary
      {
        base_slots: base_slots,
        purchased_extra_slots: purchased_extra_slots,
        total_slots: total_slots,
        used_slots: used_slots,
        available_slots: available_slots,
        at_limit: at_limit?,
        over_limit: over_limit?,
        over_limit_count: over_limit_count,
        can_activate_device: can_activate_device?,
        can_buy_extra_slot: can_buy_extra_slot?
      }
    end

    # ===== USER-FRIENDLY DISPLAY =====

    def slots_display
      if user.admin?
        "Unlimited device slots (Admin)"
      elsif total_slots == Float::INFINITY
        "Unlimited device slots"
      else
        "#{used_slots}/#{total_slots} device slots used"
      end
    end

    def slots_breakdown
      parts = []
      parts << "#{base_slots} from #{current_plan_name}"
      parts << "#{purchased_extra_slots} extra slots ($#{purchased_extra_slots * 5}/month)" if purchased_extra_slots > 0
      parts.join(" + ")
    end

    private

    def calculate_base_slots
      # Check subscription first (most specific)
      if user.subscription&.active?
        return user.subscription.plan.device_limit
      end
      
      # Fall back to role-based limits (for users without subscriptions)
      case user.role&.to_sym
      when :admin
        Float::INFINITY
      when :enterprise  
        Float::INFINITY
      when :pro
        4
      else
        2 # Basic/user role
      end
    end

    def current_plan_name
      if user.subscription&.active?
        user.subscription.plan.name
      else
        case user.role&.to_sym
        when :admin
          "Admin"
        when :enterprise
          "Enterprise (Legacy)"
        when :pro
          "Pro (Legacy)"
        else
          "Basic (Legacy)"
        end
      end
    end
  end
end