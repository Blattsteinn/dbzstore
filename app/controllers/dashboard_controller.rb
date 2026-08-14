class DashboardController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_open_support #<-- dont remember implementing this

    CACHE_KEYS = %w[
      dashboard_revenue dashboard_total_orders dashboard_paid_orders
      dashboard_pending_orders dashboard_product_views
      dashboard_product_views_today dashboard_unique_visitors_week
    ].freeze

    def self.invalidate_stats!
      # delete_multi normalizes keys with map!, so pass a mutable copy.
      Rails.cache.delete_multi(CACHE_KEYS.dup)
    end

    def index
        @revenue = Rails.cache.fetch("dashboard_revenue", expires_in: 1.hour) do
        Order.where(status: "paid").joins(:order_items)
            .sum("order_items.price * order_items.quantity")
        end

        @total_orders    = Rails.cache.fetch("dashboard_total_orders", expires_in: 5.minutes) { Order.count }
        @paid_orders     = Rails.cache.fetch("dashboard_paid_orders", expires_in: 5.minutes) { Order.where(status: "paid").count }
        @pending_orders  = Rails.cache.fetch("dashboard_pending_orders", expires_in: 5.minutes) { Order.where(status: "pending").count }
        @recent_orders   = Order.order(created_at: :desc).limit(8)

        # For Ahoy
        @product_views        = Rails.cache.fetch("dashboard_product_views", expires_in: 5.minutes) { Ahoy::Event.where(name: "Viewed products").count }
        @product_views_today  = Rails.cache.fetch("dashboard_product_views_today", expires_in: 5.minutes) { Ahoy::Event.where(name: "Viewed products").where(time: Time.current.all_day).count }
        @unique_visitors_week = Rails.cache.fetch("dashboard_unique_visitors_week", expires_in: 5.minutes) { Ahoy::Visit.where(started_at: 7.days.ago..).count }
    end

    def products_index
        @products = Product.includes(:variants).all
        @products = @products.where(game_name: params[:game_name]) if params[:game_name].present?
        render "dashboard/product/products_index"
    end

    def orders_index
        scope = Order.includes(order_items: [:product, :variant]).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        @pagy, @orders = pagy(:offset, scope, limit: 25)
        render "dashboard/order/orders_index"
    end

    def order_show
        @order = Order.includes(order_items: [:product, :variant]).find(params[:id])
        render "dashboard/order/order_show"
    end

    def feedback_index
        @pagy, @feedbacks = pagy(:offset, Feedback.order(created_at: :desc), limit: 25)
        render "dashboard/feedback/feedback_index"
    end

    def feedback_show
        @feedback = Feedback.includes(:order).find(params[:id])
        render "dashboard/feedback/feedback_show"
    end

    def faq_index
        @faqs = Faq.all
        render "dashboard/faq/faq_index"
    end

    def visitors
        @pagy, @visits = pagy(:offset,
                              Ahoy::Visit
                                .select("ahoy_visits.*, (SELECT COUNT(*) FROM ahoy_events WHERE ahoy_events.visit_id = ahoy_visits.id) AS events_count")
                                .order(started_at: :desc),
                              limit: 20)
    end

    def discount_index
        @discounts = Discount.all
        render "dashboard/discount/discount_index"
    end

    private

    def set_open_support
        @open_support = SupportMessage.where(status: "open").count
    end

end
