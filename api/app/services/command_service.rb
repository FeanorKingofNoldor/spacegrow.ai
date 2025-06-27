require 'ostruct'
# app/services/command_service.rb
class CommandService
  def initialize(device)
    @device = device
  end

  def execute(command, args = {})
    begin
      case command
      when "apply_preset"
        preset = Preset.find(args["preset_id"])
        args["settings"] = preset.settings
      when "on", "off"
        unless args["target"]&.in?(%w[lights sprayer])
          return OpenStruct.new(success?: false, error: "Invalid target: #{args["target"]} (must be 'lights' or 'sprayer')")
        end
      else
        return OpenStruct.new(success?: false, error: "Unknown command: #{command}")
      end
      command_log = CommandLog.create!(device: @device, command: command, args: args, status: "pending")
      Rails.logger.info "Queued command for #{@device.id}: #{command} with args #{args}, ID: #{command_log.id}"
      OpenStruct.new(success?: true, error: nil)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "Failed to find preset: #{e.message}"
      OpenStruct.new(success?: false, error: "Preset not found")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create command log: #{e.message}"
      OpenStruct.new(success?: false, error: e.message)
    rescue StandardError => e
      Rails.logger.error "Unexpected error queuing command: #{e.message}"
      OpenStruct.new(success?: false, error: "Internal error")
    end
  end

  private
  attr_reader :device
end