# app/controllers/api/v1/admin/dashboard_controller.rb
class Api::V1::Admin::DashboardController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::DashboardService.new.call
    
    if result[:success]
      render_success(result.except(:success), "Dashboard loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def quick_stats
    # For real-time dashboard updates if needed
    result = Admin::DashboardService.new.call
    
    if result[:success]
      quick_data = {
        users: result[:business][:users],
        devices: result[:devices],
        alerts: result[:alerts]
      }
      render_success(quick_data, "Quick stats loaded")
    else
      render_error(result[:error])
    end
  end
end