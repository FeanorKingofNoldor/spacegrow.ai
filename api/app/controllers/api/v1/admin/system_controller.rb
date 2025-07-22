# app/controllers/api/v1/admin/system_controller.rb - SIMPLIFIED FOR STARTUP
class Api::V1::Admin::SystemController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def health_check
    result = Admin::SystemService.new.health_check
    
    if result[:success]
      render_success(result.except(:success), "Health check completed")
    else
      render_error(result[:error])
    end
  end
end