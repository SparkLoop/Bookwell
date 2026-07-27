Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  UUID_PATTERN = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  get   "/appointments/:slug",
        to: "customer_appointments#show",
        as: :customer_appointment,
        constraints: { slug: UUID_PATTERN }

  patch "/appointments/:slug/cancel",
        to: "customer_appointments#cancel",
        as: :cancel_customer_appointment,
        constraints: { slug: UUID_PATTERN }

  resources :appointments, only: %i[index show edit update], constraints: { id: /\d+/ }

  root "appointments#index"
end
