# app/controllers/unsubscribe_controller.rb
class UnsubscribeController < ApplicationController
  before_action :decode_token, only: [:show, :create]
  before_action :find_user, only: [:show, :create]
  
  layout 'unsubscribe' # Simple layout without navigation
  
  # GET /unsubscribe?token=...
  # Show unsubscribe confirmation page
  def show
    if @user.nil?
      render :invalid_token, status: :not_found
      return
    end
    
    @email_type = @token_data['email_type']
    @unsubscribe_options = get_unsubscribe_options
    @user_display_name = @user.display_name
    
    # Track that unsubscribe page was viewed
    track_unsubscribe_page_view
  end
  
  # POST /unsubscribe
  # Process unsubscribe request
  def create
    if @user.nil?
      render json: { success: false, error: 'Invalid token' }, status: :not_found
      return
    end
    
    unsubscribe_type = params[:unsubscribe_type] || determine_unsubscribe_type
    reason = params[:reason]
    feedback = params[:feedback]
    
    # Validate unsubscribe type
    unless EmailUnsubscribe::UNSUBSCRIBE_TYPES.include?(unsubscribe_type)
      render json: { success: false, error: 'Invalid unsubscribe type' }, status: :bad_request
      return
    end
    
    # Process the unsubscribe
    success = EmailUnsubscribe.unsubscribe_user(
      @user,
      unsubscribe_type,
      reason: reason,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )
    
    if success
      # Add feedback if provided
      if feedback.present?
        unsubscribe_record = EmailUnsubscribe.find_by(user: @user, unsubscribe_type: unsubscribe_type)
        unsubscribe_record&.update(feedback: feedback, source: 'email_link')
      end
      
      # Track successful unsubscribe
      track_unsubscribe_success(unsubscribe_type, reason)
      
      # Respond based on request format
      respond_to do |format|
        format.html { redirect_to unsubscribe_success_path(type: unsubscribe_type) }
        format.json { 
          render json: { 
            success: true, 
            message: 'Successfully unsubscribed',
            unsubscribe_type: unsubscribe_type 
          } 
        }
      end
    else
      respond_to do |format|
        format.html { 
          flash[:error] = 'Failed to process unsubscribe request'
          redirect_to unsubscribe_path(token: params[:token])
        }
        format.json { 
          render json: { 
            success: false, 
            error: 'Failed to process unsubscribe request' 
          }, status: :unprocessable_entity 
        }
      end
    end
  rescue => e
    Rails.logger.error "📧 [UnsubscribeController] Error processing unsubscribe: #{e.message}"
    
    respond_to do |format|
      format.html { 
        flash[:error] = 'An error occurred while processing your request'
        redirect_to root_path
      }
      format.json { 
        render json: { 
          success: false, 
          error: 'An error occurred while processing your request' 
        }, status: :internal_server_error 
      }
    end
  end
  
  # GET /unsubscribe/success?type=...
  # Show success page after unsubscribe
  def success
    @unsubscribe_type = params[:type]
    @type_description = get_type_description(@unsubscribe_type)
    @resubscribe_options = get_resubscribe_options
  end
  
  # POST /unsubscribe/resubscribe?token=...
  # Allow user to resubscribe
  def resubscribe
    decode_token
    find_user
    
    if @user.nil?
      render json: { success: false, error: 'Invalid token' }, status: :not_found
      return
    end
    
    unsubscribe_type = params[:unsubscribe_type]
    unsubscribe_record = EmailUnsubscribe.find_by(user: @user, unsubscribe_type: unsubscribe_type)
    
    if unsubscribe_record
      unsubscribe_record.resubscribe!
      
      # Track resubscribe event
      track_resubscribe_success(unsubscribe_type)
      
      render json: { 
        success: true, 
        message: 'Successfully resubscribed to emails' 
      }
    else
      render json: { 
        success: false, 
        error: 'No unsubscribe record found' 
      }, status: :not_found
    end
  rescue => e
    Rails.logger.error "📧 [UnsubscribeController] Error processing resubscribe: #{e.message}"
    render json: { 
      success: false, 
      error: 'An error occurred while processing your request' 
    }, status: :internal_server_error
  end
  
  # GET /unsubscribe/preferences?token=...
  # Show email preference management page
  def preferences
    decode_token
    find_user
    
    if @user.nil?
      render :invalid_token, status: :not_found
      return
    end
    
    @preferences = @user.preferences
    @categories = UserNotificationPreference::CATEGORIES
    @current_unsubscribes = EmailUnsubscribe.where(user: @user)
                                           .pluck(:unsubscribe_type)
  end
  
  # PATCH /unsubscribe/preferences?token=...
  # Update email preferences from unsubscribe page
  def update_preferences
    decode_token
    find_user
    
    if @user.nil?
      render json: { success: false, error: 'Invalid token' }, status: :not_found
      return
    end
    
    # Update notification preferences
    result = NotificationManagement::PreferenceService.update_preferences(@user, preferences_params)
    
    if result[:success]
      render json: { 
        success: true, 
        message: 'Preferences updated successfully',
        updated_fields: result[:updated_fields]
      }
    else
      render json: { 
        success: false, 
        error: result[:error] 
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  # Decode JWT token from URL
  def decode_token
    token = params[:token]
    return unless token.present?
    
    begin
      @token_data = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })[0]
    rescue JWT::DecodeError => e
      Rails.logger.warn "📧 [UnsubscribeController] Invalid token: #{e.message}"
      @token_data = nil
    end
  end
  
  # Find user from decoded token
  def find_user
    return unless @token_data
    
    user_id = @token_data['user_id']
    @user = User.find_by(id: user_id) if user_id
  end
  
  # Determine unsubscribe type based on email type
  def determine_unsubscribe_type
    email_type = @token_data['email_type']
    
    case email_type
    when 'marketing'
      'marketing_all'
    when 'nurture'
      'nurture_sequence'
    else
      'marketing_all' # Default fallback
    end
  end
  
  # Get available unsubscribe options
  def get_unsubscribe_options
    [
      {
        type: 'marketing_all',
        title: 'All Marketing Emails',
        description: 'Unsubscribe from all marketing and promotional emails'
      },
      {
        type: 'promotional',
        title: 'Promotional Offers Only',
        description: 'Unsubscribe from promotional offers but keep educational content'
      },
      {
        type: 'nurture_sequence',
        title: 'Email Sequences',
        description: 'Unsubscribe from automated email sequences'
      }
    ]
  end
  
  # Get type description for success page
  def get_type_description(type)
    case type
    when 'marketing_all'
      'all marketing emails'
    when 'promotional'
      'promotional offers'
    when 'nurture_sequence'
      'email sequences'
    when 'educational'
      'educational content'
    else
      type&.humanize&.downcase || 'emails'
    end
  end
  
  # Get resubscribe options
  def get_resubscribe_options
    {
      email: 'support@spacegrow.ai',
      phone: '1-800-XSPACE-1',
      preferences_url: "#{Rails.application.config.app_host}/account/notifications"
    }
  end
  
  # Track unsubscribe page view
  def track_unsubscribe_page_view
    return unless defined?(Analytics::EventTrackingService)
    
    Analytics::EventTrackingService.track_user_activity(
      @user,
      'unsubscribe_page_viewed',
      {
        email_type: @email_type,
        user_agent: request.user_agent,
        referrer: request.referrer
      }
    )
  end
  
  # Track successful unsubscribe
  def track_unsubscribe_success(unsubscribe_type, reason)
    return unless defined?(Analytics::EventTrackingService)
    
    Analytics::EventTrackingService.track_user_activity(
      @user,
      'unsubscribed_via_email_link',
      {
        unsubscribe_type: unsubscribe_type,
        reason: reason,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    )
  end
  
  # Track successful resubscribe
  def track_resubscribe_success(unsubscribe_type)
    return unless defined?(Analytics::EventTrackingService)
    
    Analytics::EventTrackingService.track_user_activity(
      @user,
      'resubscribed_via_email_link',
      {
        unsubscribe_type: unsubscribe_type,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    )
  end
  
  # Strong parameters for preference updates
  def preferences_params
    params.require(:preferences).permit(
      :marketing_emails_opted_in,
      categories: {
        marketing_tips: [:email, :inapp]
      }
    )
  end
end