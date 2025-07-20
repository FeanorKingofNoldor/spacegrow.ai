# config/routes.rb - COMPLETE MERGED ROUTES WITH MONITORING
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "application#index"

  # =============================================================================
  # NEW: MONITORING & HEALTH CHECK ENDPOINTS (Public)
  # =============================================================================
  
  # Health check endpoints (public)
  mount HealthCheck::Engine, at: '/health'
  
  # Basic ping endpoint
  get '/ping', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['pong']] }
  
  # Version endpoint
  get '/version', to: proc { 
    [200, 
     { 'Content-Type' => 'application/json' }, 
     [{
       version: ENV['APP_VERSION'] || 'unknown',
       environment: Rails.env,
       ruby_version: RUBY_VERSION,
       rails_version: Rails::VERSION::STRING,
       built_at: ENV['BUILD_TIME'] || 'unknown'
     }.to_json]
    ]
  }

  # Prometheus metrics endpoint (public for scraping)
  get '/metrics', to: 'prometheus#metrics' if Rails.env.production? || ENV['ENABLE_PROMETHEUS'] == 'true'

  # =============================================================================
  # PUBLIC ROUTES (No Authentication Required)
  # =============================================================================
  
  # Email Unsubscribe (Public access required)
  get '/unsubscribe', to: 'unsubscribe#show'
  patch '/unsubscribe', to: 'unsubscribe#update'
  post '/unsubscribe/resubscribe', to: 'unsubscribe#resubscribe'

  # Analytics Tracking (Public - for email tracking pixels)
  get '/analytics/track/:tracking_id.gif', to: 'analytics#track_pixel'
  
  # =============================================================================
  # API ROUTES
  # =============================================================================
  
  namespace :api do
    namespace :v1 do
      
      # =======================================================================
      # NEW: API HEALTH CHECK ENDPOINTS
      # =======================================================================
      
      # Health check for API specifically
      get '/health', to: 'health#check'
      get '/status', to: 'health#status'
      
      # =======================================================================
      # AUTHENTICATION ROUTES (No Auth Required for Login/Register)
      # =======================================================================
      
      namespace :auth do
        # Session Management
        post '/login', to: 'sessions#create'
        delete '/logout', to: 'sessions#destroy'
        get '/sessions', to: 'sessions#index'                    # List active sessions
        delete '/sessions/:jti', to: 'sessions#destroy_session'  # Logout specific session
        delete '/sessions/logout_all', to: 'sessions#logout_all' # Logout all other sessions
        get '/me', to: 'sessions#me'                            # Current user info
        post '/refresh', to: 'sessions#refresh'                 # Refresh token
        patch '/profile', to: 'sessions#update_profile'         # Update profile
        patch '/password', to: 'sessions#change_password'       # Change password

        # Password Reset
        post '/forgot_password', to: 'passwords#create'         # Send reset email
        patch '/reset_password', to: 'passwords#update'         # Reset with token
        
        # User Registration (if using custom registration)
        post '/register', to: 'registrations#create'
        patch '/confirm', to: 'registrations#confirm'           # Email confirmation
      end

      # =======================================================================
      # ONBOARDING ROUTES (Auth Required)
      # =======================================================================
      
      namespace :onboarding do
        get '/plans', to: 'plans#index'                         # List available plans
        post '/select_plan', to: 'plans#select'                 # Select a plan
        post '/complete', to: 'onboarding#complete'             # Complete onboarding
        post '/skip', to: 'onboarding#skip'                     # Skip onboarding
      end

      # =======================================================================
      # CHART DATA ROUTES (Auth Required)
      # =======================================================================
      
      # Chart Data for Dashboard/Gauges
      get '/chart_data/latest', to: 'chart_data#latest'         # Latest chart data for gauges

      # =======================================================================
      # ESP32 DEVICE COMMUNICATION (Device Token Auth)
      # =======================================================================
      
      namespace :esp32 do
        # Device Registration & Validation
        post '/devices/register', to: 'devices#register'        # Initial device registration
        post '/devices/validate', to: 'devices#validate'        # Validate activation token
        get '/devices/status', to: 'devices#status'             # Get device status
        get '/devices/commands', to: 'devices#commands'         # Get pending commands
        patch '/devices/commands/:command_id', to: 'devices#update_command_status' # Update command status

        # Sensor Data Ingestion
        post '/sensor_data', to: 'sensor_data#create'           # Submit sensor readings
      end

      # =======================================================================
      # STORE/E-COMMERCE ROUTES (Partial Auth - Browse without, buy with auth)
      # =======================================================================
      
      namespace :store do
        # Product Catalog (Public browsing)
        get '/products', to: 'products#index'                   # List all products
        get '/products/featured', to: 'products#featured'       # Featured products
        get '/products/:id', to: 'products#show'                # Product details
        post '/products/:id/check_stock', to: 'products#check_stock' # Check availability
        
        # Shopping Cart (Auth required)
        resource :cart, only: [:show, :update, :destroy] do
          post '/items', to: 'cart#add_item'                    # Add to cart
          patch '/items/:item_id', to: 'cart#update_item'       # Update quantity
          delete '/items/:item_id', to: 'cart#remove_item'      # Remove from cart
          delete '/clear', to: 'cart#clear'                     # Clear cart
        end
        
        # Checkout Process (Auth required)
        namespace :checkout do
          post '/calculate', to: 'checkout#calculate'           # Calculate totals
          post '/payment_intent', to: 'checkout#create_payment_intent' # Stripe payment intent
          post '/complete', to: 'checkout#complete'             # Complete purchase
          get '/success/:order_id', to: 'checkout#success'      # Order confirmation
        end
      end

      # =======================================================================
      # FRONTEND USER ROUTES (Auth Required)
      # =======================================================================
      
      namespace :frontend do
        
        # Dashboard (Main user interface)
        get '/dashboard', to: 'dashboard#index'                 # Main dashboard
        get '/dashboard/summary', to: 'dashboard#summary'       # Dashboard summary data

        # Device Management
        resources :devices, only: [:index, :show, :create, :update, :destroy] do
          member do
            patch :update_settings
            patch :update_name
            post :send_command
            get :sensor_data
            get :analytics
			post :suspend
			post :wake
          end
          
          collection do
            get :available_slots
            post :activate_next
          end
        end

        # Device Configuration & Presets
        namespace :device_configuration do
          resources :presets, only: [:index, :show, :create, :update, :destroy] do
            collection do
              get :predefined
            end
          end
          
          post '/presets/:id/apply', to: 'presets#apply'
          post '/validate', to: 'device_configuration#validate'
        end

        # Order History & Billing
        resources :orders, only: [:index, :show] do
          member do
            post :retry_payment
            get :invoice
          end
        end

        # Subscription Management
        resource :subscription, only: [:show, :update] do
          post :change_plan
          post :cancel
          post :reactivate
          get :billing_history
          get :usage_analytics
          get :device_management                                # Get device management data
          post :suspend_devices                                 # Bulk suspend devices
          post :wake_devices                                    # Bulk wake devices  
          post :activate_device   
        end

        # Notification Preferences
        resource :notification_preferences, only: [:show, :update] do
          post :marketing_opt_in
          post :marketing_opt_out
          post :suppress
          delete :suppress, action: :unsuppress
          get :categories
          get :test # development/staging only
        end

        # User Profile & Settings
        get '/profile', to: 'profile#show'                      # User profile
        patch '/profile', to: 'profile#update'                  # Update profile
        patch '/profile/password', to: 'profile#change_password' # Change password
        post '/profile/avatar', to: 'profile#upload_avatar'     # Upload avatar
        delete '/profile/avatar', to: 'profile#remove_avatar'   # Remove avatar

        # Documentation & Support Pages
        get '/pages', to: 'pages#index'                         # Welcome message
        get '/pages/docs', to: 'pages#docs'                     # API Documentation
        get '/pages/api', to: 'pages#api'                       # API Reference
        get '/pages/devices', to: 'pages#devices'               # Device Documentation
        get '/pages/sensors', to: 'pages#sensors'               # Sensor Documentation
        get '/pages/troubleshooting', to: 'pages#troubleshooting' # Troubleshooting Guide
        get '/pages/support', to: 'pages#support'               # Support Contact
        get '/pages/faq', to: 'pages#faq'                       # FAQ

        # Analytics & Reports (if implemented)
        get '/analytics', to: 'analytics#index'                 # Analytics dashboard
        get '/analytics/devices', to: 'analytics#devices'       # Device analytics
        get '/analytics/sensors', to: 'analytics#sensors'       # Sensor analytics
        post '/analytics/export', to: 'analytics#export'        # Export data

        # User Settings
        get '/settings', to: 'settings#index'                   # Settings overview
        patch '/settings/general', to: 'settings#update_general' # General settings
        patch '/settings/security', to: 'settings#update_security' # Security settings
        patch '/settings/privacy', to: 'settings#update_privacy' # Privacy settings
      end

      # =======================================================================
      # ADMIN ROUTES (Admin Auth Required) - EXPANDED COMPREHENSIVE ADMIN SYSTEM
      # =======================================================================
      
      namespace :admin do
        # ===== DASHBOARD =====
        get '/dashboard', to: 'dashboard#index'
        get '/dashboard/alerts', to: 'dashboard#alerts'
        get '/dashboard/metrics', to: 'dashboard#metrics'

        # ===== USER MANAGEMENT =====
        resources :users, only: [:index, :show, :update] do
          member do
            patch :update_role
            patch :suspend
            patch :reactivate
            get :activity_log
          end
          
          collection do
            post :bulk_operations
          end
        end

        # ===== ORDER MANAGEMENT =====
        resources :orders, only: [:index, :show, :update] do
          member do
            patch :update_status
            post :refund
            post :retry_payment
          end
          
          collection do
            get :analytics
            post :export
            get :payment_failures
          end
        end

        # ===== SUBSCRIPTION MANAGEMENT =====
        resources :subscriptions, only: [:index, :show, :update] do
          member do
            patch :update_status
            post :force_plan_change
          end
          
          collection do
            get :billing_analytics
            get :churn_analysis
            get :payment_issues
          end
        end

        # ===== DEVICE FLEET MANAGEMENT =====
        resources :devices, only: [:index, :show, :update] do
          member do
            patch :update_status
            post :force_reconnect
            get :troubleshooting
          end
          
          collection do
            get :health_monitoring
            post :bulk_operations
            get :analytics
          end
        end

		# ===== SUPPORT & CUSTOMER SERVICE =====
		namespace :support do
		get '/', to: 'support#index'
		get '/device_issues', to: 'support#device_issues'
		get '/payment_issues', to: 'support#payment_issues'
		get '/insights', to: 'support#insights'
		end

        # ===== SYSTEM HEALTH & MONITORING (EXISTING + ENHANCED) =====
        namespace :system do
          get '/health', to: 'system#health'
          get '/performance', to: 'system#performance'
          get '/monitoring', to: 'system#monitoring'
        end

        # ===== NEW: REAL-TIME METRICS API ENDPOINTS =====
        namespace :metrics do
          get '/prometheus', to: 'metrics#prometheus_data'
          get '/system_resources', to: 'metrics#system_resources'
          get '/service_status', to: 'metrics#service_status'
          get '/business_metrics', to: 'metrics#business_metrics'
        end

        # ===== ANALYTICS & REPORTING =====
        namespace :analytics do
          get '/overview', to: 'analytics#overview'
          get '/business_metrics', to: 'analytics#business_metrics'
          get '/operational_metrics', to: 'analytics#operational_metrics'
          get '/user_analytics', to: 'analytics#user_analytics'
          get '/device_analytics', to: 'analytics#device_analytics'
          get '/financial_analytics', to: 'analytics#financial_analytics'
          post '/export_analytics', to: 'analytics#export_analytics'
        end

        # ===== ADMIN ALERTS & NOTIFICATIONS =====
        resources :alerts, only: [:index, :show, :update] do
          member do
            patch :acknowledge
            patch :resolve
            patch :dismiss
          end
          
          collection do
            get :active
            get :recent
            post :test_notification
          end
        end

        # ===== ADMIN ACTIVITY & AUDIT LOGS =====
        namespace :activity do
          get '/logs', to: 'activity#logs'
          get '/audit_trail/:target_type/:target_id', to: 'activity#audit_trail'
          get '/admin_summary/:admin_id', to: 'activity#admin_summary'
          get '/system_overview', to: 'activity#system_overview'
        end

        # ===== BULK OPERATIONS =====
        namespace :bulk do
          post '/users', to: 'bulk#users'
          post '/devices', to: 'bulk#devices'
          post '/subscriptions', to: 'bulk#subscriptions'
          post '/notifications', to: 'bulk#notifications'
        end

        # ===== DATA EXPORT =====
        namespace :export do
          post '/users', to: 'export#users'
          post '/orders', to: 'export#orders'
          post '/devices', to: 'export#devices'
          post '/analytics', to: 'export#analytics'
          get '/download/:export_id', to: 'export#download'
        end

        # ===== SYSTEM CONFIGURATION =====
        namespace :config do
          get '/settings', to: 'config#settings'
          patch '/settings', to: 'config#update_settings'
          get '/feature_flags', to: 'config#feature_flags'
          patch '/feature_flags', to: 'config#update_feature_flags'
          get '/maintenance_mode', to: 'config#maintenance_mode'
          patch '/maintenance_mode', to: 'config#toggle_maintenance'
        end

        # ===== ADMIN USER MANAGEMENT =====
        namespace :admin_users do
          get '/', to: 'admin_users#index'
          post '/invite', to: 'admin_users#invite'
          patch '/:id/permissions', to: 'admin_users#update_permissions'
          delete '/:id', to: 'admin_users#remove_access'
        end

        # ===== REAL-TIME MONITORING =====
        namespace :realtime do
          get '/metrics', to: 'realtime#metrics'
          get '/events', to: 'realtime#events'
          get '/alerts', to: 'realtime#alerts'
          get '/system_status', to: 'realtime#system_status'
        end

        # ===== EXISTING SIMPLE ADMIN ROUTES (PRESERVED) =====
        
        # Product Management
        get '/products', to: 'products#index'                   # List all products
        get '/products/:id', to: 'products#show'                # Product details
        post '/products', to: 'products#create'                 # Create product
        patch '/products/:id', to: 'products#update'            # Update product
        delete '/products/:id', to: 'products#destroy'          # Delete product
      end

      # =======================================================================
      # WEBHOOKS & EXTERNAL INTEGRATIONS (Special Auth)
      # =======================================================================
      
      namespace :webhooks do
        # Stripe Webhooks (Alternative location)
        post '/stripe', to: 'stripe#create'                     # Stripe webhook handler
        
        # Other potential webhooks
        post '/twilio', to: 'twilio#create'                     # SMS webhooks
        post '/sendgrid', to: 'sendgrid#create'                 # Email webhooks
        post '/analytics', to: 'analytics#create'               # Analytics webhooks
      end
    end
  end

  # =============================================================================
  # ADMIN-ONLY MONITORING INTERFACES (Web UIs)
  # =============================================================================
  
  # Protect admin monitoring interfaces with authentication
  authenticate :user, ->(user) { user.admin? } do
    # Sidekiq Web Interface (EXISTING - Preserved)
    require 'sidekiq/web'
    require 'sidekiq-scheduler/web' if defined?(Sidekiq::Scheduler)
    mount Sidekiq::Web => '/admin/sidekiq'
    
    # NEW: PgHero Database Monitoring
    mount PgHero::Engine, at: '/admin/pghero'
  end

  # =============================================================================
  # DEVELOPMENT-ONLY MONITORING ROUTES
  # =============================================================================
  
  if Rails.env.development?
    # In development, allow easier access to monitoring tools
    namespace :dev do
      mount Sidekiq::Web => '/sidekiq'
      mount PgHero::Engine => '/pghero'
      
      # Letter Opener for email preview
      mount LetterOpenerWeb::Engine, at: '/emails' if defined?(LetterOpenerWeb)
    end
  end

  # =============================================================================
  # WEBSOCKET ROUTES (ActionCable)
  # =============================================================================
  
  mount ActionCable.server => '/cable'

  # =============================================================================
  # CATCH-ALL & FALLBACK ROUTES
  # =============================================================================
  
  # API 404 Handler
  match '/api/*path', to: 'api/v1/base#not_found', via: :all
  
  # Main App Fallback (if you have a frontend app)
  # get '*path', to: 'application#index', constraints: ->(request) do
  #   !request.xhr? && request.format.html?
  # end
end