# app/services/esp32/authentication_service.rb
module DeviceCommunication::Esp32
    class AuthenticationService < ApplicationService
      def initialize(token:, ip_address:)
        @token = token
        @ip_address = ip_address
      end

      def call
        return failure('No token provided') if @token.blank?

        device = find_device_by_token
        return failure('Invalid token') unless device
        return failure('Device not active') unless device.active?

        # Update last connection
        device.update_connection!

        success(device: device)
      end

      private

      def find_device_by_token
        Device.joins(:activation_token)
              .find_by(device_activation_tokens: { token: @token })
      end

      def success(data = {})
        { success: true }.merge(data)
      end

      def failure(error)
        { success: false, error: error }
      end
    end
end