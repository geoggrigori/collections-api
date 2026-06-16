require "sidekiq/web"

Rails.application.routes.draw do
  # Health check para load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  # Dashboard do Sidekiq. Em producao, protegido por usuario/senha via env.
  if Rails.env.production? && ENV["SIDEKIQ_USER"].present?
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV["SIDEKIQ_USER"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"].to_s)
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # Webhooks de provedores externos.
  post "/webhooks/stripe", to: "webhooks/stripe#create"

  namespace :api do
    namespace :v1 do
      resources :customers, only: %i[index show create] do
        resources :invoices, only: %i[index], module: :customers
      end
      resources :invoices, only: %i[index show create]
      resources :payments, only: %i[index show create] do
        post :settle, on: :member
      end
      resources :remittances, only: %i[index show create]
    end
  end
end
