# app/controllers/api/v1/frontend/notification_preferences_controller.rb
class Api::V1::Frontend::NotificationPreferencesController < Api::V1::Frontend::ProtectedController
  before_action :set_preference_service
  
  # GET /api/v1/frontend/notification_preferences
  # Get current user's notification preferences
  def show
    result = @preference_service.get_preferences
    
    if result[:success]
      render json: {
        success: true,
        data: {
          preferences: result[:preferences],
          categories: UserNotificationPreference::CATEGORIES,
          digest_options: UserNotificationPreference::DIGEST_FREQUENCIES
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "📧 [NotificationPreferencesController] Error fetching preferences for user #{current_user.id}: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch notification preferences'
    }, status: :internal_server_error
  end
  
  # PATCH /api/v1/frontend/notification_preferences
  # Update user's notification preferences
  def update
    result = @preference_service.update_preferences(preferences_params)
    
    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        data: {
          updated_fields: result[:updated_fields],
          preferences: result[:preferences]
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "📧 [NotificationPreferencesController] Error updating preferences for user #{current_user.id}: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to update notification preferences'
    }, status: :internal_server_error
  end
  
  # POST /api/v1/frontend/notification_preferences/marketing_opt_in
  # Opt user into marketing emails
  def marketing_opt_in
    source = params[:source] || 'user_settings'
    
    result = @preference_service.opt_into_marketing(source)
    
    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        data: {
          opted_in_at: result[:opted_in_at],
          source: result[:source]
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "📧 [NotificationPreferencesController] Error opting user #{current_user.id} into marketing: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to opt into marketing emails'
    }, status: :internal_server_error
  end
  
  # POST /api/v1/frontend/notification_preferences/marketing_opt_out
  # Opt user out of marketing emails
  def marketing_opt_out
    reason = params[:reason]
    
    result = @preference_service.opt_out_of_marketing(reason)
    
    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        data: {
          opted_out_at: result[:opted_out_at],
          reason: result[:reason]
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "📧 [NotificationPreferencesController] Error opting user #{current_user.id} out of marketing: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to opt out of marketing emails'
    }, status: :internal_server_error
  end
  
  # POST /api/v1/frontend/notification_preferences/suppress
  # Temporarily suppress all notifications
  def suppress
    duration_hours = params[:duration_hours]&.to_i || 1
    reason = params[:reason]
    
    # Validate duration (max 72 hours)
    if duration_hours < 1 || duration_hours > 72
      return render json: {
        success: false,
        error: 'Duration must be between 1 and 72 hours'
      }, status: :bad_request
    end
    
    result = @preference_service.suppress_notifications(
      duration: duration_hours.hours,
      reason: reason
    )
    
    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        data: {
          suppressed_until: result[:suppressed_until],
          reason: result[:reason],
          duration_hours: duration_hours
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "📧 [NotificationPreferencesController] Error suppressing notifications for user #{current_user.id}: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to suppress notifications'
    }, status: :internal_server_error
  end
  
  # DELETE /api/v1/frontend/notification_preferences/suppress
  # Remove notification suppression
  def unsuppress
    result = @preference_service.unsuppress_notifications
    
    if result[:success]
      render json: {
        success: true,
        message: result[:message]
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "📧 [NotificationPreferencesController] Error removing suppression for user #{current_user.id}: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to remove notification suppression'
    }, status: :internal_server_error
  end
  
  # GET /api/v1/frontend/notification_preferences/categories
  # Get detailed information about notification categories
  def categories
    render json: {
      success: true,
      data: {
        categories: UserNotificationPreference::CATEGORIES.map do |key, config|
          {
            key: key,
            name: key.humanize.titleize,
            description: config[:description],
            examples: config[:examples],
            user_controllable: config[:user_controllable],
            default_email: config[:default_email],
            default_inapp: config[:default_inapp]
          }
        end
      }
    }, status: :ok
  end
  
  # GET /api/v1/frontend/notification_preferences/test
  # Test notification preferences (development/staging only)
  def test
    unless Rails.env.development? || Rails.env.staging?
      return render json: {
        success: false,
        error: 'Test endpoint only available in development/staging'
      }, status: :forbidden
    end
    
    category = params[:category] || 'device_management'
    context = {
      urgent: params[:urgent] == 'true',
      bypass_rate_limit: params[:bypass_rate_limit] == 'true'
    }
    
    email_result = @preference_service.should_send_email?(category, context)
    inapp_result = @preference_service.should_send_inapp?(category, context)
    
    render json: {
      success: true,
      data: {
        category: category,
        context: context,
        email_decision: email_result,
        inapp_decision: inapp_result,
        user_preferences: @preference_service.get_preferences[:preferences]
      }
    }, status: :ok
  end
  
  private
  
  def set_preference_service
    @preference_service = NotificationManagement::PreferenceService.new(current_user)
  end
  
  def preferences_params
    params.require(:preferences).permit(
      :digest_frequency,
      :digest_time,
      :digest_day_of_week,
      :enable_escalation,
      :escalation_delay_minutes,
      categories: {
        security_auth: [:email, :inapp],
        financial_billing: [:email, :inapp],
        critical_device_alerts: [:email, :inapp],
        device_management: [:email, :inapp],
        account_updates: [:email, :inapp],
        system_notifications: [:email, :inapp],
        reports_analytics: [:email, :inapp],
        marketing_tips: [:email, :inapp]
      }
    )
  end
end

# Add routes to config/routes.rb:
#
# namespace :api do
#   namespace :v1 do
#     namespace :frontend do
#       resource :notification_preferences, only: [:show, :update] do
#         post :marketing_opt_in
#         post :marketing_opt_out
#         post :suppress
#         delete :suppress, action: :unsuppress
#         get :categories
#         get :test # development/staging only
#       end
#     end
#   end
# end