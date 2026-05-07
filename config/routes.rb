Rails.application.routes.draw do
  root "console/dashboard#show"

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      post "auth/verify", to: "auth#verify"
      post "handshake", to: "handshake#create"

      resources :vaults, only: [] do
        resources :contents, only: [ :index ]
      end
      resources :contents, only: [ :show ]

      namespace :my do
        resource :vault, only: [ :show, :create, :update ]
        resources :contents, only: [ :index, :create, :update, :destroy ]
        resources :audit_logs, only: [ :index ]
        get "analytics/funnel", to: "analytics#funnel"
        get "analytics/content", to: "analytics#content"
        get "analytics/security", to: "analytics#security"
      end

      resource :profile, only: [ :show, :update ]
      get "account/context", to: "account#context"
    end
  end

  namespace :bkc do
    root to: "dashboard#show", as: :dashboard
    resource :vault, only: [ :create, :update ]
    resources :viewers, only: [ :index, :show, :update ]
    resources :contents, except: [ :show ]
  end

  get "console", to: "console/dashboard#show"

  namespace :console, path: "console" do
    resources :users
    post "sample_job", to: "dashboard#enqueue_sample_job"
    post "sample_mail", to: "dashboard#send_sample_mail"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
