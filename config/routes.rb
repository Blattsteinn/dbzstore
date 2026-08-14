Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  get ":game/products", to: "products#index", as: :game_products
  get ":game/products/:id", to: "products#show", as: :game_product
  get "games", to: "games#index", as: :games
  resources :products do
    member do
      patch :product_visibility
      post :duplicate_product
    end
  end



  resources :orders, only: [ :create, :destroy, :update ]
  get "orders/:public_id/cancel", to: "orders#cancel_stripe_checkout", as: "cancel_stripe_checkout_order"

  post "stripe/webhooks", to: "stripe_webhooks#create", as: "stripe_webhooks"

  # -----------------------------
  # --- Dashboard routes --------

  get "dashboard",              to: "dashboard#index",            as: "dashboard"
  get "dashboard/productss",     to: "dashboard#products_index",   as: "dashboard_products"

  get "dashboard/orders",       to: "dashboard#orders_index",    as: "dashboard_orders"
  get "dashboard/orders/:id",   to: "dashboard#order_show",      as: "dashboard_order"

  get "dashboard/feedback_index" ,to: "dashboard#feedback_index", as: "dashboard_feedbacks"
  get "dashboard/feedback_show/:id", to: "dashboard#feedback_show", as: "dashboard_feedback_show"

  get "dashboard/faq_index", to: "dashboard#faq_index", as: "dashboard_faqs"

  get "dashboard/visitors", to: "dashboard#visitors", as: "dashboard_visitors"
  get "dashboard/product_views", to: "dashboard#product_views", as: "dashboard_product_views"
  get "dashboard/discount_index", to: "dashboard#discount_index", as: "dashboard_discounts"

  # -----------------------------

  root to: redirect("/dokkan/products")


  get "instructions", to: "instructions#instructions", as: "instructions"
  get "tos", to: "tos#index", as: "tos"
  get "privacy", to: "privacy#index", as: "privacy"

  resources :feedbacks, only:  [:index, :new, :create, :destroy, :edit, :update]

  resources :support_messages, only: [:index, :show, :new, :create, :destroy, :update]
  resources :faqs, only: [:index, :new, :create, :destroy, :update, :edit]
  resources :discounts, only: [:new, :create, :destroy, :update, :edit]
  get "discounts/check_discount", to: "discounts#check_discount", as: "check_discount"
end
