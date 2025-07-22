# app/controllers/api/v1/admin/users_controller.rb
class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::UserService.new.list_users(filter_params)
    
    if result[:success]
      render_success(result.except(:success), "Users loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    result = Admin::UserService.new.user_detail(params[:id])
    
    if result[:success]
      render_success(result.except(:success), "User details loaded")
    else
      render_error(result[:error])
    end
  end

  def suspend
    result = Admin::UserService.new.suspend_user(params[:id], params[:reason])
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  def reactivate
    result = Admin::UserService.new.reactivate_user(params[:id])
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  def bulk_suspend
    result = Admin::UserService.new.bulk_suspend_users(params[:user_ids], params[:reason])
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:search, :role, :status, :plan, :page, :per_page)
  end
end