class Api::V1::ChartDataController < Api::V1::BaseController
  def latest
    # Normalize sensor_ids to an array
    sensor_ids = Array.wrap(params[:sensor_ids] || params[:sensor_id])
    mode = params[:mode]&.to_sym || :current
    Rails.logger.info "Fetching data for sensor IDs: #{sensor_ids.inspect}, mode: #{mode}"

    # Validate sensor IDs
    if sensor_ids.blank? || sensor_ids.any?(&:blank?)
      return render json: { error: 'Sensor ID(s) required' }, status: :bad_request
    end

    # Fetch data for each sensor using DataVisualization::ChartDataService
    data = sensor_ids.map { |id| DataVisualization::ChartDataService.new(id, mode: mode).fetch_data_points }

    # Handle response based on number of sensors
    if sensor_ids.length == 1
      if data.first.empty?
        render json: { message: "No data for sensor #{sensor_ids.first}" }, status: :no_content
      else
        render json: data.first, status: :ok
      end
    else
      if data.all?(&:empty?)
        render json: { message: "No data for provided sensors" }, status: :no_content
      else
        render json: data, status: :ok
      end
    end
  end
end
