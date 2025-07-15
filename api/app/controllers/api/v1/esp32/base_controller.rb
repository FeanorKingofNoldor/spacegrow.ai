# app/controllers/api/v1/esp32/base_controller.rb
class Api::V1::Esp32::BaseController < Api::V1::BaseController
  include Esp32Authenticatable
end