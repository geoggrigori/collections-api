require "sidekiq/web"

Rails.application.routes.draw do
  # Health check para load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  # Indice JSON da API (landing amigavel na raiz).
  root to: ->(_env) {
    body = {
      service: "Collections API",
      description: "AR/collections automation backend (Ruby on Rails).",
      endpoints: %w[
        /api/v1/customers /api/v1/invoices /api/v1/payments /api/v1/remittances
      ],
      dashboard: "https://collections-dashboard-beta.vercel.app",
      source: "https://github.com/geoggrigori/collections-api"
    }.to_json
    [200, { "Content-Type" => "application/json" }, [body]]
  }

  # Dashboard do Sidekiq. Em producao, protegido por usuario/senha via env.
  if Rails.env.production? && ENV["SIDEKIQ_USER"].present?
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV["SIDEKIQ_USER"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"].to_s)
    end
  end
  mount Sidekiq::Web => "/sidekiq" if ENV["REDIS_URL"].present? || Rails.env.development?

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
