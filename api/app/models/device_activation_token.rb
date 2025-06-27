# app/models/device_activation_token.rb
class DeviceActivationToken < ApplicationRecord
    belongs_to :device_type
    belongs_to :order
    belongs_to :device, optional: true
  
    validates :token, presence: true, uniqueness: true
    validates :expires_at, presence: true
  
    before_validation :generate_token, on: :create
    
    scope :unused, -> { where(device_id: nil) }
    scope :valid, -> { unused.where('expires_at > ?', Time.current) }
  
    def valid_for_activation?(device_type)
      !used? && !expired? && self.device_type == device_type
    end
  
    def used?
      device_id.present?
    end
  
    def expired?
      expires_at < Time.current
    end
  
    private
  
    def generate_token
      self.token ||= loop do
        candidate = SecureRandom.hex(24)
        break candidate unless self.class.exists?(token: candidate)
      end
    end
  end