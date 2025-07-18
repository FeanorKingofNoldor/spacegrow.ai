# app/controllers/api/v1/admin/users_controller.rb
class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    service = Admin::UserManagementService.new
    result = service.search_and_filter_users(filter_params)

    if result[:success]
      render_success(result.except(:success), "Users loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    user = User.find(params[:id])
    service = Admin::UserManagementService.new
    result = service.user_detailed_view(user)

    if result[:success]
      render_success(result.except(:success), "User details loaded")
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", [], 404)
  end

  def update_role
    user = User.find(params[:id])
    service = Admin::UserManagementService.new
    result = service.change_user_role(user, params[:role])

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", [], 404)
  end

  def suspend
    user = User.find(params[:id])
    service = Admin::UserManagementService.new
    result = service.suspend_user(user, params[:reason])

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", [], 404)
  end

  def reactivate
    user = User.find(params[:id])
    service = Admin::UserManagementService.new
    result = service.reactivate_user(user)

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", [], 404)
  end

  def activity_log
    user = User.find(params[:id])
    service = Admin::UserManagementService.new
    result = service.user_activity_log(user, params[:page])

    if result[:success]
      render_success(result.except(:success), "Activity log loaded")
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", [], 404)
  end

  def bulk_operations
    service = Admin::UserManagementService.new
    result = service.bulk_user_operations(params[:operation], params[:user_ids], bulk_params)

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:search, :role, :status, :plan, :created_after, :created_before, 
                  :last_login_after, :last_login_before, :page, :per_page, :sort_by, :sort_direction)
  end

  def bulk_params
    params.permit(:role, :reason, :notification_message)
  end
end