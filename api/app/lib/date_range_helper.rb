# app/lib/date_range_helper.rb
class DateRangeHelper
  def self.calculate_range(period)
    case period.to_s.downcase
    when 'today'
      Date.current.all_day
    when 'yesterday'
      1.day.ago.all_day
    when 'week'
      1.week.ago..Time.current
    when 'last_week'
      2.weeks.ago..1.week.ago
    when 'month'
      1.month.ago..Time.current
    when 'last_month'
      2.months.ago..1.month.ago
    when 'quarter'
      3.months.ago..Time.current
    when 'year'
      1.year.ago..Time.current
    else
      1.month.ago..Time.current
    end
  end

  def self.period_name(period)
    case period.to_s.downcase
    when 'today' then 'Today'
    when 'yesterday' then 'Yesterday'
    when 'week' then 'Last 7 days'
    when 'month' then 'Last 30 days'
    when 'quarter' then 'Last 90 days'
    when 'year' then 'Last 365 days'
    else 'Last 30 days'
    end
  end