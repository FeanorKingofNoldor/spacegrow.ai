# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include ActiveSupport::CurrentAttributes
  
  before_action :set_current_user
  
  private
  
  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end