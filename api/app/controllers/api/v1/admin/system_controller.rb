# app/controllers/api/v1/admin/system_controller.rb
class Api::V1::Admin::SystemController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::SystemService.new.monitoring_overview
    
    if result[:success]
      render_success(result.except(:success), "System monitoring loaded")
    else
      render_error(result[:error])
    end
  end

  def health_check
    result = Admin::SystemService.new.detailed_health_check
    
    if result[:success]
      render_success(result.except(:success), "Health check completed")
    else
      render_error(result[:error])
    end
  end

  def performance
    result = Admin::SystemService.new.performance_metrics
    
    if result[:success]
      render_success(result.except(:success), "Performance metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def logs
    result = Admin::SystemService.new.system_logs_summary
    
    if result[:success]
      render_success(result.except(:success), "System logs analyzed")
    else
      render_error(result[:error])
    end
  end
end
