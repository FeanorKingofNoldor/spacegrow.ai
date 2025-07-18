# app/models/concerns/admin_searchable.rb
module AdminSearchable
  extend ActiveSupport::Concern

  included do
    scope :admin_search, ->(query) { search_by_admin_fields(query) if query.present? }
  end

  class_methods do
    def search_by_admin_fields(query)
      # Define searchable fields per model
      case name
      when 'User'
        admin_user_search(query)
      when 'Device'
        admin_device_search(query)
      when 'Order'
        admin_order_search(query)
      when 'Subscription'
        admin_subscription_search(query)
      else
        where("id::text ILIKE ?", "%#{query}%")
      end
    end

    private

    def admin_user_search(query)
      joins("LEFT JOIN subscriptions ON subscriptions.user_id = users.id")
        .joins("LEFT JOIN plans ON plans.id = subscriptions.plan_id")
        .where(
          "users.email ILIKE ? OR users.display_name ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.id::text = ? OR plans.name ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", query, "%#{query}%"
        ).distinct
    end

    def admin_device_search(query)
      joins(:user)
        .joins("LEFT JOIN device_types ON device_types.id = devices.device_type_id")
        .where(
          "devices.name ILIKE ? OR devices.id::text = ? OR users.email ILIKE ? OR device_types.name ILIKE ?",
          "%#{query}%", query, "%#{query}%", "%#{query}%"
        ).distinct
    end

    def admin_order_search(query)
      joins(:user)
        .where(
          "orders.id::text = ? OR users.email ILIKE ? OR orders.status ILIKE ?",
          query, "%#{query}%", "%#{query}%"
        ).distinct
    end

    def admin_subscription_search(query)
      joins(:user, :plan)
        .where(
          "subscriptions.id::text = ? OR users.email ILIKE ? OR plans.name ILIKE ? OR subscriptions.status ILIKE ?",
          query, "%#{query}%", "%#{query}%", "%#{query}%"
        ).distinct
    end
  end

  # Instance methods for search relevance
  def search_relevance_score(query)
    return 0 if query.blank?
    
    score = 0
    query_downcase = query.downcase
    
    # Exact ID match gets highest score
    score += 100 if id.to_s == query
    
    # Email exact match (for users)
    if respond_to?(:email) && email.downcase == query_downcase
      score += 90
    end
    
    # Email partial match
    if respond_to?(:email) && email.downcase.include?(query_downcase)
      score += 70
    end
    
    # Name matches
    if respond_to?(:name) && name&.downcase&.include?(query_downcase)
      score += 60
    end
    
    if respond_to?(:display_name) && display_name&.downcase&.include?(query_downcase)
      score += 60
    end
    
    score
  end
end