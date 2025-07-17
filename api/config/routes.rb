# config/routes.rb - COMPLETE ROUTES AUDIT
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "application#index"

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
        
        # Alternative store root
        get '/', to: 'store#index'                              # Store homepage
        get '/:id', to: 'store#show'                            # Alternative product view

        # Shopping Cart (Auth Required)
        get '/cart', to: 'carts#show'                           # View cart
        post '/cart/add', to: 'carts#add_item'                 # Add item to cart
        delete '/cart/remove', to: 'carts#remove_item'         # Remove item
        patch '/cart/update', to: 'carts#update_quantity'      # Update quantity
        delete '/cart', to: 'carts#clear'                      # Clear cart

        # Orders (Auth Required)
        get '/orders', to: 'orders#index'                       # List user orders
        get '/orders/:id', to: 'orders#show'                    # Order details
        post '/orders', to: 'orders#create'                     # Create order
        patch '/orders/:id', to: 'orders#update'                # Update order
        post '/orders/:id/mark_paid', to: 'orders#mark_paid'    # Mark as paid (testing)

        # Checkout (Auth Required)
        get '/checkout', to: 'checkout#show'                     # Checkout page
        post '/checkout', to: 'checkout#create'                 # Create Stripe session

        # Stripe Webhooks (No Auth - Stripe signature verification)
        post '/webhooks/stripe', to: 'stripe_webhooks#create'   # Stripe webhook handler
      end

      # =======================================================================
      # FRONTEND APPLICATION ROUTES (User Auth Required)
      # =======================================================================
      
      namespace :frontend do
        # Dashboard
        get '/dashboard', to: 'dashboard#index'                 # Main dashboard data
        get '/dashboard/devices', to: 'dashboard#devices'       # Device list
        get '/dashboard/devices/:id', to: 'dashboard#device'    # Device details

        # Device Management
        get '/devices', to: 'devices#index'                     # List user devices  
        get '/devices/:id', to: 'devices#show'                  # Device details
        post '/devices', to: 'devices#create'                   # Create device
        patch '/devices/:id', to: 'devices#update'              # Update device
        delete '/devices/:id', to: 'devices#destroy'            # Delete device
        post '/devices/:id/activate', to: 'devices#activate'    # Activate device
        post '/devices/:id/suspend', to: 'devices#suspend'      # Suspend device
        post '/devices/:id/wake', to: 'devices#wake'           # Wake from suspension
        
        # Device Commands
        get '/devices/:id/commands', to: 'devices#commands'     # Device commands
        post '/devices/:id/commands', to: 'devices#send_command' # Send command

        # Sensor Data (Read-only for frontend)
        get '/devices/:device_id/sensors', to: 'sensor_data#index'           # List sensors
        get '/devices/:device_id/sensors/:sensor_id', to: 'sensor_data#show' # Sensor details
        get '/devices/:device_id/sensors/:sensor_id/data', to: 'sensor_data#data' # Sensor readings

        # Device Presets
        get '/presets/device_type/:device_type_id', to: 'presets#by_device_type'      # Predefined presets
        get '/presets/user/:device_type_id', to: 'presets#user_by_device_type'       # User presets
        get '/presets/:id', to: 'presets#show'                                       # Preset details
        post '/presets', to: 'presets#create'                                        # Create preset
        patch '/presets/:id', to: 'presets#update'                                   # Update preset
        delete '/presets/:id', to: 'presets#destroy'                                 # Delete preset
        post '/presets/validate', to: 'presets#validate'                             # Validate preset settings

        # Subscription Management
        get '/subscriptions', to: 'subscriptions#index'                              # List plans & current subscription
        get '/subscriptions/device_management', to: 'subscriptions#device_management' # Device slot management
        post '/subscriptions/activate_device', to: 'subscriptions#activate_device'   # Activate specific device
        post '/subscriptions/wake_devices', to: 'subscriptions#wake_devices'         # Wake multiple devices
        post '/subscriptions/suspend_devices', to: 'subscriptions#suspend_devices'   # Suspend multiple devices
        post '/subscriptions/preview_change', to: 'subscriptions#preview_change'     # Preview plan change
        post '/subscriptions/change_plan', to: 'subscriptions#change_plan'           # Execute plan change
        delete '/subscriptions/cancel', to: 'subscriptions#cancel'                   # Cancel subscription
        post '/subscriptions/add_device_slot', to: 'subscriptions#add_device_slot'   # Add device slot
        delete '/subscriptions/remove_device_slot', to: 'subscriptions#remove_device_slot' # Remove device slot

        # Notification Preferences
        resource :notification_preferences, only: [:show, :update] do
          post :marketing_opt_in                                # Opt into marketing
          post :marketing_opt_out                               # Opt out of marketing
          post :suppress                                        # Temporarily suppress all
          delete :suppress, action: :unsuppress                # Remove suppression
          get :categories                                       # List notification categories
          get :test                                             # Test preferences (dev/staging only)
        end

        # User Profile Management
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
      # ADMIN ROUTES (Admin Auth Required)
      # =======================================================================
      
      namespace :admin do
        # Admin Dashboard
        get '/dashboard', to: 'dashboard#index'                 # Admin stats & overview

        # User Management
        get '/users', to: 'users#index'                         # List all users
        get '/users/:id', to: 'users#show'                      # User details
        patch '/users/:id', to: 'users#update'                  # Update user
        delete '/users/:id', to: 'users#destroy'                # Delete user
        post '/users/:id/suspend', to: 'users#suspend'          # Suspend user
        post '/users/:id/unsuspend', to: 'users#unsuspend'      # Unsuspend user
        post '/users/:id/reset_password', to: 'users#reset_password' # Force password reset

        # Device Management
        get '/devices', to: 'devices#index'                     # List all devices
        get '/devices/:id', to: 'devices#show'                  # Device details
        patch '/devices/:id', to: 'devices#update'              # Update device
        delete '/devices/:id', to: 'devices#destroy'            # Delete device
        post '/devices/:id/force_activate', to: 'devices#force_activate' # Force activate
        post '/devices/:id/force_suspend', to: 'devices#force_suspend'   # Force suspend

        # Order Management
        get '/orders', to: 'orders#index'                       # List all orders
        get '/orders/:id', to: 'orders#show'                    # Order details
        patch '/orders/:id', to: 'orders#update'                # Update order status
        post '/orders/:id/refund', to: 'orders#refund'          # Process refund

        # Subscription Management
        get '/subscriptions', to: 'subscriptions#index'         # List all subscriptions
        get '/subscriptions/:id', to: 'subscriptions#show'      # Subscription details
        patch '/subscriptions/:id', to: 'subscriptions#update'  # Update subscription
        post '/subscriptions/:id/force_cancel', to: 'subscriptions#force_cancel' # Force cancel

        # Product Management
        get '/products', to: 'products#index'                   # List all products
        get '/products/:id', to: 'products#show'                # Product details
        post '/products', to: 'products#create'                 # Create product
        patch '/products/:id', to: 'products#update'            # Update product
        delete '/products/:id', to: 'products#destroy'          # Delete product

        # Analytics & Reports
        get '/analytics', to: 'analytics#index'                 # Admin analytics
        get '/analytics/users', to: 'analytics#users'           # User analytics
        get '/analytics/revenue', to: 'analytics#revenue'       # Revenue analytics
        get '/analytics/devices', to: 'analytics#devices'       # Device analytics
        post '/analytics/export', to: 'analytics#export'        # Export admin data

        # System Management
        get '/system', to: 'system#index'                       # System status
        get '/system/health', to: 'system#health'               # Health check
        get '/system/logs', to: 'system#logs'                   # System logs
        post '/system/maintenance', to: 'system#toggle_maintenance' # Maintenance mode
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

      # =======================================================================
      # HEALTH & STATUS ENDPOINTS (Public/Internal)
      # =======================================================================
      
      get '/health', to: 'health#check'                         # Health check
      get '/status', to: 'health#status'                        # Detailed status
      get '/version', to: 'health#version'                      # Application version
    end
  end

  # =============================================================================
  # SIDEKIQ WEB INTERFACE (Admin Only - Add authentication)
  # =============================================================================
  
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'
  
  # Sidekiq Web UI (protect with admin authentication)
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
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