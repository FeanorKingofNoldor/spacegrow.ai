# config/routes.rb
Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes (public - no auth required)
      devise_scope :user do
        post 'auth/login', to: 'auth/sessions#create'
        delete 'auth/logout', to: 'auth/sessions#destroy'
        post 'auth/signup', to: 'auth/registrations#create'
      end

      # ESP32 device routes (device authentication required)
      namespace :esp32 do
        post 'devices/register', to: 'devices#register'
        post 'devices/validate', to: 'devices#validate'
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
        
        # Orders (auth required)
        resources :orders, only: [:index, :show]
        
        # Stripe webhooks (public webhook endpoint)
        post 'webhooks/stripe', to: 'stripe_webhooks#create'
      end

      # Frontend routes (JWT authentication required)
      namespace :frontend do
        # Dashboard
        get 'dashboard', to: 'dashboard#index'
        get 'dashboard/devices', to: 'dashboard#devices'
        get 'dashboard/device/:id', to: 'dashboard#device'
        
        # Device management
        resources :devices, only: [:index, :show, :create, :update, :destroy] do
          member do
            patch :update_status
          end
          resources :commands, only: [:create]
        end
        
        # Subscriptions
        resources :subscriptions, only: [:index] do
          collection do
            get :choose_plan
            post :select_plan
          end
          member do
            delete :cancel
            post :add_device_slot
            delete :remove_device_slot
          end
        end
        
        # Presets
        resources :presets, only: [:create, :show] do
          collection do
            get :user_by_device_type
          end
        end
        
        # Onboarding
        resources :onboarding, only: [] do
          collection do
            get :choose_plan
            post :select_plan
          end
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