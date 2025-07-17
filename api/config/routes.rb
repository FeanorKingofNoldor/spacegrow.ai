# config/routes.rb
Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable for WebSocket connections
  mount ActionCable.server, at: '/cable'

  # ===== UNSUBSCRIBE SYSTEM =====
  # Public unsubscribe routes (no authentication required)
  get '/unsubscribe', to: 'unsubscribe#show'
  post '/unsubscribe', to: 'unsubscribe#create'
  get '/unsubscribe/success', to: 'unsubscribe#success'
  post '/unsubscribe/resubscribe', to: 'unsubscribe#resubscribe'
  
  # Unsubscribe preference management
  get '/unsubscribe/preferences', to: 'unsubscribe#preferences'
  patch '/unsubscribe/preferences', to: 'unsubscribe#update_preferences'

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes (public - no auth required)
      devise_scope :user do
        post 'auth/login', to: 'auth/sessions#create'
        delete 'auth/logout', to: 'auth/sessions#destroy'
        post 'auth/signup', to: 'auth/registrations#create'
        
        # Additional auth endpoints
        get 'auth/me', to: 'auth/sessions#me'
        post 'auth/refresh', to: 'auth/sessions#refresh'
        patch 'auth/update_profile', to: 'auth/sessions#update_profile'
        post 'auth/forgot_password', to: 'auth/passwords#create'
        put 'auth/reset_password', to: 'auth/passwords#update'
        patch 'auth/change_password', to: 'auth/sessions#change_password'
        get 'auth/sessions', to: 'auth/sessions#index'
        delete 'auth/sessions/:jti', to: 'auth/sessions#destroy_session'
        delete 'auth/sessions/logout_all', to: 'auth/sessions#logout_all' 
      end

      # ESP32 device routes (device authentication required)
      namespace :esp32 do
        post 'devices/register', to: 'devices#register'
        post 'devices/validate', to: 'devices#validate'
        get 'devices/status', to: 'devices#status'                    # ✅ ADD THIS
        get 'devices/commands', to: 'devices#commands'
        post 'devices/commands/:command_id/status', to: 'devices#update_command_status'
        post 'sensor_data', to: 'sensor_data#create'
      end

      # Store routes (public browsing, auth required for orders)
      namespace :store do
        # Product browsing (public)
        resources :products, only: [:index, :show] do
          collection do
            get :featured
          end
          member do
            get :check_stock
          end
        end
        
        # Cart management (session-based, no auth required)
        resource :cart, only: [:show] do
          post :add
          delete :remove
          patch :update_quantity
          delete :clear
        end
        
        # Checkout (auth required)
        resource :checkout, only: [:show, :create] do
          get :success
          get :cancel
        end
        
        # Orders (auth required) - ✅ UPDATED: Added create and update actions
        resources :orders, only: [:index, :show, :create, :update] do
          member do
            post :mark_paid        # For testing - mark order as paid
            post :generate_tokens  # Manually generate activation tokens
          end
        end
        
        # Stripe webhooks (public webhook endpoint)
        post 'webhooks/stripe', to: 'stripe_webhooks#create'
      end

      # Frontend routes (JWT authentication required)
      namespace :frontend do
        # Dashboard
        get 'dashboard', to: 'dashboard#index'
        get 'dashboard/devices', to: 'dashboard#devices'
        get 'dashboard/device/:id', to:'dashboard#device'
        
        # Device management with suspension
        resources :devices, only: [:index, :show, :create, :update, :destroy] do
          member do
            patch :update_status
            post :suspend        # ✅ NEW
            post :wake            # ✅ NEW
          end
          resources :commands, only: [:create]
        end
        
        resources :subscriptions, only: [:index] do
          collection do
            # Plan selection and changes
            post :select_plan         
            post :preview_change      
            post :change_plan         
            post :schedule_change     
            get :devices_for_selection
            
            # Subscription management
            post :cancel              
            post :add_device_slot     
            post :remove_device_slot  
            
            # ✅ NEW: Device slot management routes
            get :slot_overview        # Get current slot usage
            post :purchase_extra_slot # Buy additional slots
            delete 'extra_slots/:slot_id', to: 'subscriptions#cancel_extra_slot' # Cancel specific slot
            
            # Device state management
            get :device_management
            post :activate_device
            post :wake_devices
            post :suspend_devices
          end
        end
        
        # Presets
        resources :presets, only: [:create, :show, :update, :destroy] do
          collection do
            get :by_device_type
            get :user_by_device_type
            post :validate
          end
        end
        
        # Onboarding routes for new user plan selection
        namespace :onboarding do
          get :choose_plan    
          post :select_plan   
        end
        
        # ✅ NEW: Notification Preferences API routes
        resource :notification_preferences, only: [:show, :update] do
          post :marketing_opt_in
          post :marketing_opt_out
          post :suppress
          delete :suppress, action: :unsuppress
          get :categories
          get :test # development/staging only
        end
        
        # Static pages/documentation
        resources :pages, only: [] do
          collection do
            get :index
            get :docs
            get :api
            get :devices
            get :sensors
            get :troubleshooting
            get :support
            get :faq
          end
        end
        
        # User profile
        resource :profile, only: [:show, :update]
      end

      # Chart data API (could be public for demo or protected)
      get 'chart_data/latest', to: 'chart_data#latest'

      # Admin routes (admin authentication required)
      namespace :admin do
        get 'dashboard', to: 'dashboard#index'
        
        # ===== MARKETING & NURTURE EMAIL MANAGEMENT =====
        namespace :marketing do
          # Marketing email triggers (admin only)
          post '/send_pro_onboarding/:order_id', to: 'emails#send_pro_onboarding'
          post '/send_accessory_follow_up/:order_id', to: 'emails#send_accessory_follow_up'
          post '/send_device_promotion/:user_id', to: 'emails#send_device_promotion'
          post '/send_pro_features_follow_up/:user_id', to: 'emails#send_pro_features_follow_up'
          
          # Nurture email triggers (admin only)
          post '/send_educational_content/:user_id', to: 'emails#send_educational_content'
          post '/send_case_studies/:user_id', to: 'emails#send_case_studies'
          post '/send_seasonal_promotion/:user_id', to: 'emails#send_seasonal_promotion'
          post '/send_win_back_campaign/:user_id', to: 'emails#send_win_back_campaign'
          post '/send_final_attempt/:user_id', to: 'emails#send_final_attempt'
          
          # Analytics and management
          get '/unsubscribe_analytics', to: 'analytics#unsubscribe_stats'
          get '/email_performance', to: 'analytics#email_performance'
        end
        
        # Admin API for triggering marketing emails
        resources :marketing_emails, only: [] do
          collection do
            post :trigger_pro_onboarding
            post :trigger_accessory_follow_up
            post :trigger_device_promotion
            post :trigger_nurture_sequence
            post :bulk_unsubscribe
            get :email_analytics
          end
        end
        
        # Unsubscribe management API
        resources :unsubscribes, only: [:index, :show, :create, :destroy] do
          collection do
            get :statistics
            post :bulk_unsubscribe
            post :bulk_resubscribe
          end
        end
      end
      
      # ===== PUBLIC API ENDPOINTS =====
      namespace :public do
        # Unsubscribe via API (for integrations)
        post '/unsubscribe', to: 'unsubscribe#create'
        get '/unsubscribe/verify/:token', to: 'unsubscribe#verify_token'
      end
    end
  end
end