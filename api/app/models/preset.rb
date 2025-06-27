# app/models/preset.rb
class Preset < ApplicationRecord
  belongs_to :device_type
  belongs_to :device, optional: true
  belongs_to :user, optional: true
  validates :name, presence: true, uniqueness: { scope: [:device_type_id, :user_id] }
  validates :settings, presence: true  # Just ensure it’s not nil/empty
  scope :predefined, -> { where(is_user_defined: false, user_id: nil) }
  scope :profiles, ->(user) { where(is_user_defined: true, user_id: user.id) }

  before_save :normalize_settings

  private

  def normalize_settings
    settings.transform_values!(&:deep_symbolize_keys) if settings.is_a?(Hash)
    Rails.logger.info "Normalized settings for preset ID: #{id || 'new'}, settings: #{settings}"
  end
end