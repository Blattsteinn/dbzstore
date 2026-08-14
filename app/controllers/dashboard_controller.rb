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
        @product_views        = Rails.cache.fetch("dashboard_product_views", expires_in: 5.minutes) { Ahoy::Event.where(name: "Viewed product").count }
        @product_views_today  = Rails.cache.fetch("dashboard_product_views_today", expires_in: 5.minutes) { Ahoy::Event.where(name: "Viewed product").where(time: Time.current.all_day).count }
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

    def product_views
        scope = Ahoy::Event.includes(:visit)
            .where(name: "Viewed product")
            .order(time: :desc)

        @pagy, @views = pagy(:offset, scope, limit: 25)

        # All-time most-viewed products (grouped by the product id stored on the event).
        top = Ahoy::Event.where(name: "Viewed product")
            .where.not("properties->>'product' IS NULL")
            .group("properties->>'product'")
            .count
            .sort_by { |_, count| -count }
            .first(10)

        @top_counts = top
        @top_products = Product.where(id: top.map { |id, _| id.to_i }).index_by(&:id)

        # Resolve products for the current page of events in one query (for linking).
        page_ids = @views.map { |e| e.properties&.[]("product") }.compact.map(&:to_i).uniq
        @page_products = Product.where(id: page_ids).index_by(&:id)
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
