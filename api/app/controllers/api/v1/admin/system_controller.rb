# app/controllers/api/v1/admin/system_controller.rb
class Api::V1::Admin::SystemController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def health
    service = Admin::SystemHealthService.new
    result = service.system_health_check

    if result[:success]
      render_success(result.except(:success), "System health check completed")
    else
      render_error(result[:error])
    end
  end

  def performance
    service = Admin::SystemHealthService.new
    result = service.performance_metrics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Performance metrics loaded")
    else
      render_error(result[:error])
    end
  end

  def monitoring
    service = Admin::SystemHealthService.new
    result = service.monitoring_dashboard(params[:period])

    if result[:success]
      render_success(result.except(:success), "Monitoring dashboard loaded")
    else
      render_error(result[:error])
    end
  end

  def maintenance
    service = Admin::SystemHealthService.new
    result = service.maintenance_status

    if result[:success]
      render_success(result.except(:success), "Maintenance status loaded")
    else
      render_error(result[:error])
    end
  end

  def logs
    service = Admin::SystemHealthService.new
    result = service.system_logs_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "System logs analyzed")
    else
      render_error(result[:error])
    end
  end

  def alerts
    service = Admin::SystemHealthService.new
    result = service.system_alerts_overview

    if result[:success]
      render_success(result.except(:success), "System alerts loaded")
    else
      render_error(result[:error])
    end
  end

  def infrastructure
    service = Admin::SystemHealthService.new
    result = service.infrastructure_status

    if result[:success]
      render_success(result.except(:success), "Infrastructure status loaded")
    else
      render_error(result[:error])
    end
  end

  def diagnostics
    service = Admin::SystemHealthService.new
    result = service.run_system_diagnostics

    if result[:success]
      render_success(result.except(:success), "System diagnostics completed")
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:level, :category, :time_range, :limit, :offset)
  end
end