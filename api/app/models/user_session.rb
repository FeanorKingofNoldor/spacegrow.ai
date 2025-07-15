# app/models/user_session.rb
class UserSession < ApplicationRecord
  belongs_to :user
  
  validates :jti, presence: true, uniqueness: true
  validates :ip_address, presence: true
  validates :expires_at, presence: true
  
  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :recent, -> { order(last_active_at: :desc) }
  
  before_create :set_last_active
  
  # Parse device info from user agent string
  def device_type
    return 'Unknown Device' if device_info.blank?
    
    agent = device_info.downcase
    
    # Mobile devices
    return 'iPhone' if agent.include?('iphone')
    return 'iPad' if agent.include?('ipad')
    return 'Android Phone' if agent.include?('android') && agent.include?('mobile')
    return 'Android Tablet' if agent.include?('android')
    
    # Desktop browsers
    browser = detect_browser(agent)
    os = detect_os(agent)
    
    "#{browser} on #{os}"
  end
  
  # Check if this session is expired
  def expired?
    expires_at <= Time.current
  end
  
  # Check if session was active recently (within last hour)
  def recently_active?
    last_active_at > 1.hour.ago
  end
  
  # Format last active time
  def formatted_last_active
    return 'Active now' if recently_active?
    
    time_diff = Time.current - last_active_at
    
    if time_diff < 1.hour
      "#{(time_diff / 1.minute).round} minute#{'s' if (time_diff / 1.minute).round != 1} ago"
    elsif time_diff < 1.day
      "#{(time_diff / 1.hour).round} hour#{'s' if (time_diff / 1.hour).round != 1} ago"
    else
      "#{(time_diff / 1.day).round} day#{'s' if (time_diff / 1.day).round != 1} ago"
    end
  end
  
  # Touch last active timestamp
  def touch_last_active!
    update_column(:last_active_at, Time.current)
  end
  
  # Class method to cleanup expired sessions
  def self.cleanup_expired!
    expired_count = expired.count
    expired.delete_all
    
    # Also cleanup expired JWT denylist entries
    JwtDenylist.where('exp <= ?', Time.current).delete_all
    
    Rails.logger.info "Cleaned up #{expired_count} expired user sessions"
    expired_count
  end
  
  # Class method to enforce session limit per user
  def self.enforce_session_limit!(user, limit = 5)
    active_sessions = user.user_sessions.active.recent
    
    if active_sessions.count >= limit
      # Remove oldest sessions beyond limit
      sessions_to_remove = active_sessions.offset(limit - 1)
      
      sessions_to_remove.each do |session|
        # Add to denylist to invalidate tokens
        JwtDenylist.create!(
          jti: session.jti,
          exp: session.expires_at
        )
      end
      
      sessions_to_remove.delete_all
    end
  end
  
  private
  
  def set_last_active
    self.last_active_at = Time.current
  end
  
  def detect_browser(agent)
    return 'Edge' if agent.include?('edg/')
    return 'Chrome' if agent.include?('chrome') && !agent.include?('edge')
    return 'Firefox' if agent.include?('firefox')
    return 'Safari' if agent.include?('safari') && !agent.include?('chrome')
    return 'Opera' if agent.include?('opera') || agent.include?('opr/')
    
    'Unknown Browser'
  end
  
  def detect_os(agent)
    return 'Windows' if agent.include?('windows')
    return 'macOS' if agent.include?('mac os x') || agent.include?('macos')
    return 'Linux' if agent.include?('linux')
    return 'iOS' if agent.include?('iphone') || agent.include?('ipad')
    return 'Android' if agent.include?('android')
    
    'Unknown OS'
  end
end