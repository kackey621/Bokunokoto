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
        get "analytics/attribution", to: "analytics#attribution"
        get "analytics/accessibility", to: "analytics#accessibility"
        get "analytics/greetings", to: "analytics#greetings"
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
    resources :access_links, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]
    get "forensics", to: "forensics#index"
    get "forensics/users/:user_id/timeline", to: "forensics#timeline", as: :forensics_user_timeline
    get "analytics", to: "analytics#show"
    get "analytics/locations", to: "analytics#locations"
  end

  get "console", to: "console/dashboard#show"

  namespace :console, path: "console" do
    resources :users
    post "sample_job", to: "dashboard#enqueue_sample_job"
    post "sample_mail", to: "dashboard#send_sample_mail"
  end

  namespace :super_admin do
    root to: "dashboard#show"
    get "firestore", to: "firestore#index", as: :firestore_index
    get "fcm", to: "fcm#index", as: :fcm_index
    post "fcm", to: "fcm#create"
    get "remote_config", to: "remote_config#index", as: :remote_config_index
    post "remote_config", to: "remote_config#create"
    get "feature_flags", to: "feature_flags#index", as: :feature_flags
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
