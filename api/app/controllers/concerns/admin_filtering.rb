# app/controllers/concerns/admin_filtering.rb
module AdminFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_admin_filter_params, only: [:index]
  end

  private

  def set_admin_filter_params
    @filter_params = {
      search: params[:search],
      status: params[:status],
      created_after: parse_date(params[:created_after]),
      created_before: parse_date(params[:created_before]),
      sort_by: params[:sort_by] || 'created_at',
      sort_direction: params[:sort_direction] || 'desc',
      page: params[:page]&.to_i || 1,
      per_page: [params[:per_page]&.to_i || 25, 100].min
    }
  end

  def apply_admin_filters(scope)
    # Apply search
    scope = scope.admin_search(@filter_params[:search]) if @filter_params[:search].present?
    
    # Apply status filter
    scope = scope.where(status: @filter_params[:status]) if @filter_params[:status].present?
    
    # Apply date filters
    scope = scope.where(created_at: @filter_params[:created_after]..) if @filter_params[:created_after]
    scope = scope.where(created_at: ..@filter_params[:created_before]) if @filter_params[:created_before]
    
    # Apply sorting
    scope = apply_admin_sorting(scope)
    
    scope
  end

  def apply_admin_sorting(scope)
    sort_field = @filter_params[:sort_by]
    direction = @filter_params[:sort_direction] == 'desc' ? :desc : :asc
    
    case sort_field
    when 'created_at', 'updated_at'
      scope.order(sort_field => direction)
    when 'email' # For users
      scope.respond_to?(:joins) ? scope.joins(:user).order("users.email #{direction}") : scope.order(email: direction)
    when 'name' # For devices or other named entities
      scope.order(name: direction)
    when 'status'
      scope.order(status: direction)
    else
      scope.order(created_at: :desc)
    end
  end

  def paginate_results(scope)
    scope.page(@filter_params[:page]).per(@filter_params[:per_page])
  end

  def build_pagination_meta(paginated_results)
    {
      current_page: @filter_params[:page],
      per_page: @filter_params[:per_page],
      total_pages: paginated_results.total_pages,
      total_count: paginated_results.total_count,
      has_next: @filter_params[:page] < paginated_results.total_pages,
      has_prev: @filter_params[:page] > 1
    }
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    
    begin
      Date.parse(date_string)
    rescue ArgumentError
      nil
    end
  end

  def filter_summary
    {
      applied_filters: @filter_params.compact,
      filter_count: @filter_params.compact.count - 3 # Exclude page, per_page, sort_by defaults
    }
  end
end