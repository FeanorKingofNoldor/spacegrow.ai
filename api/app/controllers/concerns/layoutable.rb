# app/controllers/concerns/layoutable.rb
module Layoutable
  extend ActiveSupport::Concern
  
  included do
    layout :determine_layout
  end
  
  private
  
  def determine_layout
    if current_user
      current_user.admin? ? 'admin' : 'authenticated'
    else
      'public'
    end
  end

  def admin?
    current_user&.email == Rails.application.credentials.admin_email
  end
end