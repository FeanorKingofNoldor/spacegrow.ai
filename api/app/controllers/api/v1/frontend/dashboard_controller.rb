class Api::V1::Frontend::DevicesController < Api::V1::Frontend::ProtectedController
 before_action :set_device, only: [:show, :update, :destroy, :update_status]

 def index
   devices = current_user.devices.includes(:device_type)
   
   render json: {
     status: 'success',
     data: devices.map { |device| device_json(device) },
     message: devices.any? ? "Found #{devices.count} devices" : "No devices found"
   }
 end

 def show
   authorize @device
   render json: {
     status: 'success',
     data: detailed_device_json(@device)
   }
 end

 def create
   device = current_user.devices.build(device_params)
   
   if device.save
     render json: {
       status: 'success',
       message: 'Device created successfully',
       data: device_json(device)
     }, status: :created
   else
     render json: {
       status: 'error',
       errors: device.errors.full_messages
     }, status: :unprocessable_entity
   end
 end

 def update
   authorize @device
   if @device.update(device_params)
     render json: {
       status: 'success',
       message: 'Device updated successfully',
       data: device_json(@device)
     }
   else
     render json: {
       status: 'error',
       errors: @device.errors.full_messages
     }, status: :unprocessable_entity
   end
 end

 def destroy
   authorize @device
   @device.destroy
   render json: {
     status: 'success',
     message: 'Device deleted successfully'
   }
 end

 def update_status
   authorize @device
   authorize @device
   if @device.update(status_params)
     render json: {
       status: 'success',
       message: 'Device status updated successfully',
       data: device_json(@device)
     }
   else
     render json: {
       status: 'error',
       errors: @device.errors.full_messages
     }, status: :unprocessable_entity
   end
 end

 private

 def set_device
   @device = current_user.devices.find(params[:id])
 end

 def device_params
   params.require(:device).permit(:name, :device_type_id, :status)
 end

 def status_params
   params.require(:device).permit(:status)
 end

 def device_json(device)
   {
     id: device.id,
     name: device.name,
     status: device.status,
     alert_status: device.alert_status,
     device_type: device.device_type&.name,
     last_connection: device.last_connection,
     created_at: device.created_at,
     updated_at: device.updated_at
   }
 end

 def detailed_device_json(device)
   {
     device: device_json(device),
     sensor_groups: group_sensors_by_type(device),
     latest_readings: get_latest_readings(device),
     device_status: calculate_device_status(device),
     presets: [], # Add your presets logic when ready
     profiles: [] # Add your profiles logic when ready
   }
 end

 def group_sensors_by_type(device)
   device.device_sensors.includes(:sensor_type).group_by { |sensor| sensor.sensor_type.name }.transform_values do |sensors|
     sensors.map do |sensor|
       {
         id: sensor.id,
         type: sensor.sensor_type.name,
         status: sensor.current_status,
         last_reading: sensor.sensor_data.order(:timestamp).last&.value,
         sensor_type: {
           id: sensor.sensor_type.id,
           name: sensor.sensor_type.name,
           unit: sensor.sensor_type.unit,
           min_value: sensor.sensor_type.min_value,
           max_value: sensor.sensor_type.max_value,
           error_low_min: sensor.sensor_type.error_low_min,
           error_low_max: sensor.sensor_type.error_low_max,
           warning_low_min: sensor.sensor_type.warning_low_min,
           warning_low_max: sensor.sensor_type.warning_low_max,
           normal_min: sensor.sensor_type.normal_min,
           normal_max: sensor.sensor_type.normal_max,
           warning_high_min: sensor.sensor_type.warning_high_min,
           warning_high_max: sensor.sensor_type.warning_high_max,
           error_high_min: sensor.sensor_type.error_high_min,
           error_high_max: sensor.sensor_type.error_high_max
         }
       }
     end
   end
 end

 def get_latest_readings(device)
   # Return hash of sensor_id => latest_reading_value
   device.device_sensors.includes(:sensor_data).each_with_object({}) do |sensor, hash|
     latest = sensor.sensor_data.order(:timestamp).last
     hash[sensor.id] = latest&.value
   end
 end

  def calculate_device_status(device)
    # Device status calculation logic
    {
      overall_status: device.status,
      alert_level: device.alert_status,
      last_seen: device.last_connection,
      connection_status: device.last_connection && 
        device.last_connection > 10.minutes.ago ? 'online' : 'offline'
    }
  end
end