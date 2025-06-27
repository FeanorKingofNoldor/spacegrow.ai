class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :devices, dependent: :destroy
  has_one :subscription
  has_one :plan, through: :subscription
  has_many :orders

  # Enums
  enum role: {
    user: 0,
    pro: 1,
    admin: 2
  }

  validates :timezone, inclusion: { 
    in: ActiveSupport::TimeZone.all.map(&:name), 
    message: "must be a valid IANA timezone" 
  }, allow_blank: true

  # Display the user's name
  def display_name
    email.split('@').first.capitalize
  end

  # Device management methods  
  def device_limit
    case role.to_sym
    when :admin then Float::INFINITY
    when :pro then 10
    else 2
    end
  end

  def available_device_slots
    return Float::INFINITY if admin?
    [device_limit - devices.count, 0].max
  end

  def can_add_device?
    admin? || devices.count < device_limit
  end
end
