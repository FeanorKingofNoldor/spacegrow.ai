# app/services/admin/subscription_list_service.rb
module Admin
  class SubscriptionListService < ApplicationService
    def initialize(filter_params = {})
      @filter_params = filter_params
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

    private

    attr_reader :filter_params

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
      subscriptions = subscriptions.where(created_at: filter_params[:created_after]..) if filter_params[:created_after].present?
      subscriptions = subscriptions.where(created_at: ..filter_params[:created_before]) if filter_params[:created_before].present?
      subscriptions
    end

    def apply_search_filter(subscriptions)
      return subscriptions unless filter_params[:search].present?
      
      search_term = filter_params[:search]
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
      else
        subscriptions.order(created_at: :desc)
      end
    end

    def apply_pagination(subscriptions)
      page = filter_params[:page]&.to_i || 1
      per_page = [filter_params[:per_page]&.to_i || 25, 100].min
      
      subscriptions.page(page).per(per_page)
    end

    def build_pagination_data(paginated_subscriptions)
      {
        current_page: paginated_subscriptions.current_page,
        per_page: paginated_subscriptions.limit_value,
        total_pages: paginated_subscriptions.total_pages,
        total_count: paginated_subscriptions.total_count,
        has_next_page: paginated_subscriptions.next_page.present?,
        has_prev_page: paginated_subscriptions.prev_page.present?
      }
    end

    def build_subscriptions_summary(subscriptions)
      {
        total_subscriptions: subscriptions.count,
        active_subscriptions: subscriptions.where(status: 'active').count,
        past_due_subscriptions: subscriptions.where(status: 'past_due').count,
        canceled_subscriptions: subscriptions.where(status: 'canceled').count,
        total_mrr: subscriptions.where(status: 'active').joins(:plan).sum('plans.monthly_price'),
        avg_subscription_age: calculate_avg_subscription_age(subscriptions)
      }
    end

    def build_subscription_filter_options
      {
        statuses: Subscription.distinct.pluck(:status).compact,
        plans: Plan.select(:id, :name).order(:name),
        sort_options: [
          { value: 'created_at', label: 'Date Created' },
          { value: 'user_email', label: 'User Email' },
          { value: 'plan_name', label: 'Plan Name' }
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
          monthly_cost: subscription.monthly_cost,
          device_limit: subscription.device_limit,
          devices_count: subscription.user.devices.count,
          created_at: subscription.created_at.iso8601,
          current_period_start: subscription.current_period_start&.iso8601,
          current_period_end: subscription.current_period_end&.iso8601,
          days_past_due: subscription.past_due? ? (Date.current - subscription.current_period_end.to_date).to_i : 0
        }
      end
    end

    def calculate_avg_subscription_age(subscriptions)
      return 0 if subscriptions.empty?
      
      total_age_days = subscriptions.sum { |sub| (Time.current - sub.created_at).to_i / 1.day }
      (total_age_days.to_f / subscriptions.count).round(1)
    end

    def sort_direction
      filter_params[:sort_direction] == 'desc' ? :desc : :asc
    end

    def sort_direction_sql
      filter_params[:sort_direction] == 'desc' ? 'DESC' : 'ASC'
    end
  end
end