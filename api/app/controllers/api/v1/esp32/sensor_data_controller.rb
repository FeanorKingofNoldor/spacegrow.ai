# app/controllers/api/v1/esp32/sensor_data_controller.rb
class Api::V1::Esp32::SensorDataController < Api::V1::Esp32::BaseController
  def create
    payload = parse_json_payload
    return render_invalid_json unless payload

    result = DeviceCommunication::Esp32::SensorDataProcessingService.call(
      device: current_device,
      payload: payload
    )

    if result[:success]
      render json: { status: 'success' }, status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def parse_json_payload
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    nil
  end

  def render_invalid_json
    render json: { error: 'Invalid JSON' }, status: :bad_request
  end
end