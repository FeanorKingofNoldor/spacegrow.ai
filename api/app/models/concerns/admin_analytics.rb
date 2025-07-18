# app/models/concerns/admin_analytics.rb
module AdminAnalytics
  extend ActiveSupport::Concern

  included do
    scope :admin_analytics_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
    scope :admin_recent, ->(days = 7) { where(created_at: days.days.ago..Time.current) }
  end

  class_methods do
    def admin_growth_analysis(period = 'month')
      date_range = calculate_admin_date_range(period)
      previous_range = calculate_previous_period_range(period)
      
      current_count = where(created_at: date_range).count
      previous_count = where(created_at: previous_range).count
      
      growth_rate = previous_count > 0 ? ((current_count - previous_count).to_f / previous_count * 100).round(2) : 0
      
      {
        current_period: current_count,
        previous_period: previous_count,
        growth_rate: growth_rate,
        growth_direction: growth_rate > 0 ? 'positive' : (growth_rate < 0 ? 'negative' : 'neutral')
      }
    end

    def admin_activity_heatmap(days = 30)
      # Generate activity heatmap data for admin dashboards
      data = where(created_at: days.days.ago..Time.current)
             .group_by_day(:created_at)
             .count
      
      # Fill missing days with 0
      (days.days.ago.to_date..Date.current).each do |date|
        data[date] ||= 0
      end
      
      data.sort.to_h
    end

    def admin_hourly_distribution(days = 7)
      # Analyze activity by hour of day
      where(created_at: days.days.ago..Time.current)
        .group_by_hour_of_day(:created_at)
        .count
    end

    def admin_trend_analysis(metric_field = :created_at, period = 'week')
      # Analyze trends for any date field
      case period
      when 'week'
        group_by_day(metric_field, last: 7).count
      when 'month'
        group_by_week(metric_field, last: 4).count
      when 'quarter'
        group_by_month(metric_field, last: 3).count
      when 'year'
        group_by_month(metric_field, last: 12).count
      else
        group_by_day(metric_field, last: 7).count
      end
    end

    private

    def calculate_admin_date_range(period)
      case period
      when 'week'
        1.week.ago..Time.current
      when 'month'
        1.month.ago..Time.current
      when 'quarter'
        3.months.ago..Time.current
      when 'year'
        1.year.ago..Time.current
      else
        1.month.ago..Time.current
      end
    end

    def calculate_previous_period_range(period)
      case period
      when 'week'
        2.weeks.ago..1.week.ago
      when 'month'
        2.months.ago..1.month.ago
      when 'quarter'
        6.months.ago..3.months.ago
      when 'year'
        2.years.ago..1.year.ago
      else
        2.months.ago..1.month.ago
      end
    end
  end

  # Instance methods for analytics
  def admin_age_in_days
    (Time.current - created_at).to_i / 1.day
  end

  def admin_lifecycle_stage
    age_days = admin_age_in_days
    
    case age_days
    when 0..7
      'new'
    when 8..30
      'recent'
    when 31..90
      'established'
    when 91..365
      'mature'
    else
      'veteran'
    end
  end

  def admin_activity_score
    # Calculate activity score based on recency and frequency
    # This is a base implementation - each model can override
    base_score = 50
    
    # Recency bonus
    if updated_at > 1.day.ago
      base_score += 30
    elsif updated_at > 1.week.ago
      base_score += 15
    elsif updated_at > 1.month.ago
      base_score += 5
    end
    
    # Age penalty
    age_penalty = [admin_age_in_days / 10, 25].min
    base_score -= age_penalty
    
    [base_score, 0].max
  end
end