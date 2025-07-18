# app/controllers/api/v1/admin/devices_controller.rb
class Api::V1::Admin::DevicesController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    service = Admin::DeviceFleetService.new
    result = service.fleet_overview(filter_params)

    if result[:success]
      render_success(result.except(:success), "Device fleet loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    device = Device.find(params[:id])
    service = Admin::DeviceFleetService.new
    result = service.device_detailed_view(device)

    if result[:success]
      render_success(result.except(:success), "Device details loaded")
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Device not found", [], 404)
  end

  def health_monitoring
    service = Admin::DeviceFleetService.new
    result = service.fleet_health_analysis(params[:period])

    if result[:success]
      render_success(result.except(:success), "Fleet health analysis loaded")
    else
      render_error(result[:error])
    end
  end

  def update_status
    device = Device.find(params[:id])
    service = Admin::DeviceFleetService.new
    result = service.admin_update_device_status(device, params[:status], params[:reason])

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Device not found", [], 404)
  end

  def bulk_operations
    service = Admin::DeviceFleetService.new
    result = service.bulk_device_operations(params[:operation], params[:device_ids], bulk_params)

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  end

  def troubleshooting
    device = Device.find(params[:id])
    service = Admin::DeviceFleetService.new
    result = service.device_troubleshooting_info(device)

    if result[:success]
      render_success(result.except(:success), "Troubleshooting info loaded")
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Device not found", [], 404)
  end

  def analytics
    service = Admin::DeviceFleetService.new
    result = service.device_analytics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Device analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def force_reconnect
    device = Device.find(params[:id])
    service = Admin::DeviceFleetService.new
    result = service.force_device_reconnect(device)

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Device not found", [], 404)
  end

  private

  def filter_params
    params.permit(:status, :user_id, :device_type_id, :last_connection_before, 
                  :last_connection_after, :created_after, :created_before,
                  :page, :per_page, :sort_by, :sort_direction, :search)
  end

  def bulk_params
    params.permit(:reason, :new_status, :notification_message)
  end
end