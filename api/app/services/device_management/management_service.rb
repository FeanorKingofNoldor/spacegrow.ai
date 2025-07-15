module DeviceManagement
  class ManagementService < ApplicationService
    class << self
      # ✅ KEEP: Simple device operations
      def suspend_devices(device_ids, reason: 'subscription_limit')
        return [] if device_ids.empty?

        devices = Device.where(id: device_ids)
        suspended_devices = []

        Device.transaction do
          devices.each do |device|
            if device.operational?
              device.suspend!(reason: reason)
              suspended_devices << {
                id: device.id,
                name: device.name,
                suspended_reason: reason
              }
            end
          end
        end

        Rails.logger.info "Suspended #{suspended_devices.count} devices"
        suspended_devices
      end

      def wake_devices(device_ids)
        return [] if device_ids.empty?

        devices = Device.where(id: device_ids, status: 'suspended')
        woken_devices = []

        Device.transaction do
          devices.each do |device|
            device.wake!
            woken_devices << {
              id: device.id,
              name: device.name,
              new_status: device.status
            }
          end
        end

        Rails.logger.info "Woken #{woken_devices.count} devices"
        woken_devices
      end

      # ✅ KEEP: Simple device summary (no complex recommendations)
      def get_device_summary(user)
        devices = user.devices.includes(:device_type)
        
        {
          total: devices.count,
          operational: devices.operational.count,
          suspended: devices.suspended.count,
          pending: devices.pending.count,
          disabled: devices.disabled.count
        }
      end
    end
  end
end