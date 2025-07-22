# app/controllers/api/v1/admin/devices_controller.rb
class Api::V1::Admin::DevicesController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::DeviceService.new.device_list(filter_params)
    
    if result[:success]
      render_success(result.except(:success), "Devices loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    result = Admin::DeviceService.new.device_detail(params[:id])
    
    if result[:success]
      render_success(result.except(:success), "Device details loaded")
    else
      render_error(result[:error])
    end
  end

  def fleet_overview
    result = Admin::DeviceService.new.fleet_overview
    
    if result[:success]
      render_success(result.except(:success), "Fleet overview loaded")
    else
      render_error(result[:error])
    end
  end

  def restart
    result = Admin::DeviceService.new.restart_device(params[:id])
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  def troubleshoot
    result = Admin::DeviceService.new.device_troubleshooting(params[:id])
    
    if result[:success]
      render_success(result.except(:success), "Troubleshooting info loaded")
    else
      render_error(result[:error])
    end
  end

  def bulk_suspend
    result = Admin::DeviceService.new.bulk_suspend_devices(params[:device_ids], params[:reason])
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :device_type, :user_id, :search, :page, :per_page)
  end
end