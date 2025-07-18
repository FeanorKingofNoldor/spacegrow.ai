# app/models/support_request.rb
class SupportRequest < ApplicationRecord
  # ===== CONSTANTS =====
  
  STATUSES = %w[open in_progress pending_customer resolved closed].freeze
  PRIORITIES = %w[low medium high critical].freeze
  CATEGORIES = %w[
    technical
    billing
    account
    device_setup
    connection_issues
    data_accuracy
    feature_request
    bug_report
    general_inquiry
  ].freeze
  
  SOURCES = %w[email chat phone web_form api].freeze

  # ===== VALIDATIONS =====
  
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :subject, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 5000 }
  validates :requester_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # ===== ASSOCIATIONS =====
  
  belongs_to :user, optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true
  has_many :support_request_updates, dependent: :destroy

  # ===== SCOPES =====
  
  scope :open, -> { where(status: 'open') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :pending_customer, -> { where(status: 'pending_customer') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :closed, -> { where(status: 'closed') }
  scope :active, -> { where(status: ['open', 'in_progress', 'pending_customer']) }
  
  scope :critical, -> { where(priority: 'critical') }
  scope :high, -> { where(priority: 'high') }
  scope :medium, -> { where(priority: 'medium') }
  scope :low, -> { where(priority: 'low') }
  
  scope :by_category, ->(category) { where(category: category) }
  scope :by_source, ->(source) { where(source: source) }
  scope :recent, ->(days = 7) { where(created_at: days.days.ago..Time.current) }
  scope :overdue, -> { where(status: ['open', 'in_progress'], created_at: ..48.hours.ago) }
  scope :unassigned, -> { where(assigned_to: nil, status: ['open', 'in_progress']) }

  # ===== CALLBACKS =====
  
  before_create :set_defaults
  after_create :send_confirmation_email
  after_update :track_status_changes, if: :saved_change_to_status?

  # ===== INSTANCE METHODS =====
  
  def assign_to!(user)
    update!(
      assigned_to: user,
      assigned_at: Time.current,
      status: (status == 'open' ? 'in_progress' : status)
    )
    
    add_update("Assigned to #{user.display_name}")
  end

  def escalate_priority!
    new_priority = case priority
                   when 'low' then 'medium'
                   when 'medium' then 'high'
                   when 'high' then 'critical'
                   else priority
                   end
    
    if new_priority != priority
      update!(priority: new_priority)
      add_update("Priority escalated to #{new_priority}")
    end
  end

  def mark_pending_customer!(message = nil)
    update!(status: 'pending_customer', pending_customer_since: Time.current)
    add_update("Marked as pending customer response: #{message}")
  end

  def resolve!(resolution_message)
    update!(
      status: 'resolved',
      resolved_at: Time.current,
      resolution_message: resolution_message
    )
    
    add_update("Resolved: #{resolution_message}")
    send_resolution_email
  end

  def close!(close_reason = nil)
    update!(
      status: 'closed',
      closed_at: Time.current,
      close_reason: close_reason
    )
    
    add_update("Closed: #{close_reason}")
  end

  def reopen!(reason = nil)
    update!(
      status: 'open',
      reopened_at: Time.current,
      reopen_reason: reason
    )
    
    add_update("Reopened: #{reason}")
  end

  def add_update(message, user = nil)
    support_request_updates.create!(
      message: message,
      user: user,
      created_at: Time.current
    )
  end

  # Status checks
  def open?; status == 'open'; end
  def in_progress?; status == 'in_progress'; end
  def pending_customer?; status == 'pending_customer'; end
  def resolved?; status == 'resolved'; end
  def closed?; status == 'closed'; end
  def active?; ['open', 'in_progress', 'pending_customer'].include?(status); end

  # Priority checks
  def critical?; priority == 'critical'; end
  def high?; priority == 'high'; end
  def medium?; priority == 'medium'; end
  def low?; priority == 'low'; end

  def overdue?
    active? && created_at < 48.hours.ago
  end

  def response_time
    return nil unless first_response_at
    first_response_at - created_at
  end

  def resolution_time
    return nil unless resolved_at
    resolved_at - created_at
  end

  def age
    Time.current - created_at
  end

  def priority_color
    case priority
    when 'critical' then 'red'
    when 'high' then 'orange'
    when 'medium' then 'yellow'
    when 'low' then 'green'
    else 'gray'
    end
  end

  def status_color
    case status
    when 'open' then 'red'
    when 'in_progress' then 'blue'
    when 'pending_customer' then 'yellow'
    when 'resolved' then 'green'
    when 'closed' then 'gray'
    else 'gray'
    end
  end

  # ===== CLASS METHODS =====
  
  def self.create_from_email(email_data)
    create!(
      requester_email: email_data[:from],
      subject: email_data[:subject],
      description: email_data[:body],
      source: 'email',
      category: determine_category_from_content(email_data[:subject], email_data[:body]),
      priority: determine_priority_from_content(email_data[:subject], email_data[:body])
    )
  end

  def self.support_metrics(period = 30.days)
    requests_in_period = where(created_at: period.ago..Time.current)
    
    {
      total_requests: requests_in_period.count,
      open_requests: requests_in_period.open.count,
      resolved_requests: requests_in_period.resolved.count,
      average_response_time: calculate_average_response_time(requests_in_period),
      average_resolution_time: calculate_average_resolution_time(requests_in_period),
      satisfaction_score: calculate_satisfaction_score(requests_in_period),
      by_category: requests_in_period.group(:category).count,
      by_priority: requests_in_period.group(:priority).count,
      by_source: requests_in_period.group(:source).count
    }
  end

  def self.overdue_requests
    overdue.order(created_at: :asc)
  end

  def self.unassigned_requests
    unassigned.order(priority: :desc, created_at: :asc)
  end

  private

  def set_defaults
    self.status ||= 'open'
    self.priority ||= 'medium'
    self.created_at ||= Time.current
  end

  def send_confirmation_email
    # This would integrate with your email system
    Rails.logger.info "Sending support request confirmation to #{requester_email}"
  end

  def send_resolution_email
    # This would integrate with your email system
    Rails.logger.info "Sending resolution email to #{requester_email}"
  end

  def track_status_changes
    old_status = saved_changes['status'][0]
    new_status = saved_changes['status'][1]
    
    case new_status
    when 'in_progress'
      self.update_column(:started_at, Time.current) if started_at.nil?
    when 'resolved'
      self.update_column(:resolved_at, Time.current) if resolved_at.nil?
    when 'closed'
      self.update_column(:closed_at, Time.current) if closed_at.nil?
    end
  end

  def self.determine_category_from_content(subject, body)
    content = "#{subject} #{body}".downcase
    
    return 'billing' if content.match?(/billing|payment|invoice|subscription|plan|charge/)
    return 'device_setup' if content.match?(/setup|install|configure|activation/)
    return 'connection_issues' if content.match?(/connect|offline|network|wifi/)
    return 'data_accuracy' if content.match?(/data|reading|sensor|inaccurate/)
    return 'bug_report' if content.match?(/bug|error|crash|broken/)
    return 'feature_request' if content.match?(/feature|enhancement|suggestion|improvement/)
    
    'general_inquiry'
  end

  def self.determine_priority_from_content(subject, body)
    content = "#{subject} #{body}".downcase
    
    return 'critical' if content.match?(/urgent|critical|emergency|down|not working/)
    return 'high' if content.match?(/important|asap|soon|problem/)
    return 'low' if content.match?(/question|info|when you can|no rush/)
    
    'medium'
  end

  def self.calculate_average_response_time(requests)
    response_times = requests.where.not(first_response_at: nil)
                           .pluck(:created_at, :first_response_at)
                           .map { |created, responded| responded - created }
    
    return 0 if response_times.empty?
    
    average_seconds = response_times.sum / response_times.count
    (average_seconds / 1.hour).round(2)
  end

  def self.calculate_average_resolution_time(requests)
    resolution_times = requests.where.not(resolved_at: nil)
                             .pluck(:created_at, :resolved_at)
                             .map { |created, resolved| resolved - created }
    
    return 0 if resolution_times.empty?
    
    average_seconds = resolution_times.sum / resolution_times.count
    (average_seconds / 1.hour).round(2)
  end

  def self.calculate_satisfaction_score(requests)
    # This would integrate with your satisfaction survey system
    4.2 # Placeholder
  end
end