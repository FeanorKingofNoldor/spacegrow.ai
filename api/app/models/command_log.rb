# app/models/command_log.rb
class CommandLog < ApplicationRecord
  belongs_to :device

  validates :command, presence: true
  validates :status, inclusion: { in: %w[pending sent executed failed] }

  enum status: {
    pending: "pending",
    sent: "sent",
    executed: "executed",
    failed: "failed"
  }, _default: "pending"

  scope :pending, -> { where(status: "pending") }
end