# config/routes.rb
Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable for WebSocket connections
  mount ActionCable.server, at: '/cable'

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
        # Add other admin routes as needed
      end
    end
  end
end