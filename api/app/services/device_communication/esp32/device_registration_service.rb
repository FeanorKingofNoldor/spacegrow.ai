module DeviceCommunication::Esp32
  class DeviceRegistrationService < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      activation_token = DeviceActivationToken.find_by(token: @token)
      
      return failure('Invalid activation token') unless activation_token
      return failure('Token already used') if activation_token.used?
      return failure('Token expired') if activation_token.expired?

      success(
        token: activation_token.token,
        commands: [],
        device_type: activation_token.device_type
      )
    end

    private

    def success(data)
      OpenStruct.new(success?: true, **data)
    end

    def failure(error)
      OpenStruct.new(success?: false, error: error)
    end
  end
end