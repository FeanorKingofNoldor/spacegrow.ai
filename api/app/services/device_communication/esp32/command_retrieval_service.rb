module DeviceCommunication::Esp32
  class CommandRetrievalService < ApplicationService
    def initialize(device)
      @device = device
    end

    def call
      return failure('Device not active') unless @device.active?

      pending_commands = @device.command_logs.pending.map do |cmd|
        {
          id: cmd.id,
          command: cmd.command,
          args: cmd.args,
          created_at: cmd.created_at
        }
      end

      success(commands: pending_commands)
    end

    private

    def success(data = {})
      { success: true }.merge(data)
    end

    def failure(error)
      { success: false, error: error }
    end
  end
end