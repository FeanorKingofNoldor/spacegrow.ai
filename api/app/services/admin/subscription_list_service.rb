# app/services/admin/subscription_list_service.rb
module Admin
  class SubscriptionListService < ApplicationService
    DEFAULT_PAGE_SIZE = 25
    MAX_PAGE_SIZE = 100

    def initialize(filter_params = {})
      @filter_params = filter_params.with_indifferent_access
    end

    def call
      begin
        subscriptions = build_subscription_query
        paginated_subscriptions = apply_pagination(subscriptions)

        success(
          subscriptions: serialize_subscriptions_list(paginated_subscriptions),
          pagination: build_pagination_data(paginated_subscriptions),
          summary: build_subscriptions_summary(subscriptions),
          filters: build_subscription_filter_options,
          total_count: subscriptions.count
        )
      rescue => e
        Rails.logger.error "Subscription listing error: #{e.message}"
        failure("Failed to load subscriptions: #{e.message}")
      end
    end

	def billing_analytics(period = 'month')
		success(
			subscription_metrics: Subscription.analytics_for_period(period),
			plan_distribution: Subscription.active.joins(:plan).group('plans.name').count,
			growth_metrics: calculate_subscription_growth(period)
		)
	end

	def payment_issues_summary
		success(
			past_due_subscriptions: Subscription.past_due.includes(:user, :plan).limit(50).map(&:admin_summary),
			failed_payments: Order.payment_failure_summary,
			summary: {
			total_past_due: Subscription.past_due.count,
			total_amount_at_risk: Subscription.past_due.joins(:plan).sum('plans.monthly_price')
			}
		)
	end

    private

    attr_reader :filter_params

	def calculate_subscription_growth(period)
		date_range = DateRangeHelper.calculate_range(period)
		{
			new_subscriptions: Subscription.where(created_at: date_range).count,
			cancellations: Subscription.where(status: 'canceled', updated_at: date_range).count,
			net_growth: Subscription.where(created_at: date_range).count - 
						Subscription.where(status: 'canceled', updated_at: date_range).count
		}
	end

    def build_subscription_query
      subscriptions = Subscription.includes(:user, :plan, :extra_device_slots)
      
      # Apply filters using existing rich query methods
      subscriptions = apply_status_filter(subscriptions)
      subscriptions = apply_plan_filter(subscriptions)
      subscriptions = apply_date_filters(subscriptions)
      subscriptions = apply_search_filter(subscriptions)
      subscriptions = apply_sorting(subscriptions)
      
      subscriptions
    end

    def apply_status_filter(subscriptions)
      return subscriptions unless filter_params[:status].present?
      subscriptions.where(status: filter_params[:status])
    end

    def apply_plan_filter(subscriptions)
      return subscriptions unless filter_params[:plan_id].present?
      subscriptions.where(plan_id: filter_params[:plan_id])
    end

    def apply_date_filters(subscriptions)
      if filter_params[:created_after].present?
        subscriptions = subscriptions.where(created_at: filter_params[:created_after]..)
      end
      
      if filter_params[:created_before].present?
        subscriptions = subscriptions.where(created_at: ..filter_params[:created_before])
      end
      
      subscriptions
    end

    def apply_search_filter(subscriptions)
      return subscriptions unless filter_params[:search].present?
      
      search_term = filter_params[:search].strip
      return subscriptions if search_term.blank?
      
      subscriptions.joins(:user).where(
        "users.email ILIKE ? OR users.display_name ILIKE ? OR subscriptions.id::text = ?",
        "%#{search_term}%", "%#{search_term}%", search_term
      )
    end

    def apply_sorting(subscriptions)
      case filter_params[:sort_by]
      when 'created_at'
        subscriptions.order(created_at: sort_direction)
      when 'user_email'
        subscriptions.joins(:user).order("users.email #{sort_direction_sql}")
      when 'plan_name'
        subscriptions.joins(:plan).order("plans.name #{sort_direction_sql}")
      when 'status'
        subscriptions.order(status: sort_direction)
      when 'monthly_cost'
        subscriptions.joins(:plan).order("plans.monthly_price #{sort_direction_sql}")
      else
        subscriptions.order(created_at: :desc)
      end
    end

    def apply_pagination(subscriptions)
      page = [filter_params[:page].to_i, 1].max
      per_page = [filter_params[:per_page].to_i.nonzero? || DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE].min
      
      if subscriptions.respond_to?(:page)
        subscriptions.page(page).per(per_page)
      else
        # Fallback pagination
        subscriptions.limit(per_page).offset((page - 1) * per_page)
      end
    end

    def build_pagination_data(paginated_subscriptions)
      if paginated_subscriptions.respond_to?(:current_page)
        {
          current_page: paginated_subscriptions.current_page,
          per_page: paginated_subscriptions.limit_value,
          total_pages: paginated_subscriptions.total_pages,
          total_count: paginated_subscriptions.total_count,
          has_next_page: paginated_subscriptions.next_page.present?,
          has_prev_page: paginated_subscriptions.prev_page.present?
        }
      else
        page = [filter_params[:page].to_i, 1].max
        per_page = [filter_params[:per_page].to_i.nonzero? || DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE].min
        total_count = paginated_subscriptions.count
        total_pages = (total_count.to_f / per_page).ceil
        
        {
          current_page: page,
          per_page: per_page,
          total_pages: total_pages,
          total_count: total_count,
          has_next_page: page < total_pages,
          has_prev_page: page > 1
        }
      end
    end

    def build_subscriptions_summary(subscriptions)
      {
        total_subscriptions: subscriptions.count,
        active_subscriptions: subscriptions.where(status: 'active').count,
        past_due_subscriptions: subscriptions.where(status: 'past_due').count,
        canceled_subscriptions: subscriptions.where(status: 'canceled').count,
        total_mrr: calculate_total_mrr(subscriptions),
        avg_subscription_age: calculate_avg_subscription_age(subscriptions)
      }
    end

    def build_subscription_filter_options
      {
        statuses: Subscription.distinct.pluck(:status).compact.map do |status|
          { value: status, label: status.humanize }
        end,
        plans: Plan.select(:id, :name, :monthly_price).order(:monthly_price),
        sort_options: [
          { value: 'created_at', label: 'Date Created' },
          { value: 'user_email', label: 'User Email' },
          { value: 'plan_name', label: 'Plan Name' },
          { value: 'status', label: 'Status' },
          { value: 'monthly_cost', label: 'Monthly Cost' }
        ]
      }
    end

    def serialize_subscriptions_list(subscriptions)
      subscriptions.map do |subscription|
        {
          id: subscription.id,
          user_email: subscription.user.email,
          user_name: subscription.user.display_name,
          plan_name: subscription.plan&.name,
          status: subscription.status,
          monthly_cost: subscription.plan&.monthly_price || subscription.monthly_cost || 0,
          device_limit: subscription.device_limit,
          devices_count: subscription.user.devices.count,
          extra_device_slots_count: subscription.extra_device_slots.count,
          created_at: subscription.created_at.iso8601,
          current_period_start: subscription.current_period_start&.iso8601,
          current_period_end: subscription.current_period_end&.iso8601,
          canceled_at: subscription.canceled_at&.iso8601,
          days_past_due: calculate_days_past_due(subscription)
        }
      end
    end

    def calculate_total_mrr(subscriptions)
      active_subscriptions = subscriptions.where(status: 'active')
      plan_mrr = active_subscriptions.joins(:plan).sum('plans.monthly_price')
      extra_slots_mrr = active_subscriptions.joins(:extra_device_slots).sum('extra_device_slots.monthly_cost')
      plan_mrr + extra_slots_mrr
    end

    def calculate_avg_subscription_age(subscriptions)
      return 0 if subscriptions.empty?
      
      total_age_days = subscriptions.sum { |sub| (Time.current - sub.created_at).to_i / 1.day }
      (total_age_days.to_f / subscriptions.count).round(1)
    end

    def calculate_days_past_due(subscription)
      return 0 unless subscription.status == 'past_due' && subscription.current_period_end
      
      days = (Date.current - subscription.current_period_end.to_date).to_i
      [days, 0].max
    end

    def sort_direction
      filter_params[:sort_direction] == 'desc' ? :desc : :asc
    end

    def sort_direction_sql
      filter_params[:sort_direction] == 'desc' ? 'DESC' : 'ASC'
    end
  end
end