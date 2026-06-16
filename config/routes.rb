Rails.application.routes.draw do
  # Health check para load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :customers, only: %i[index show create] do
        resources :invoices, only: %i[index], module: :customers
      end
      resources :invoices, only: %i[index show create]
    end
  end
end
