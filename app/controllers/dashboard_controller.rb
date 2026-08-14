class DashboardController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_open_support #<-- dont remember implementing this

    def index
        @revenue = Rails.cache.fetch("dashboard_revenue", expires_in: 1.hour) do
        Order.where(status: "paid").joins(:order_items)
            .sum("order_items.price * order_items.quantity")
        end

        @total_orders    = Order.count
        @paid_orders     = Order.where(status: "paid").count
        @pending_orders  = Order.where(status: "pending").count
        @recent_orders   = Order.order(created_at: :desc).limit(8)

        # For Ahoy
        @product_views        = Ahoy::Event.where(name: "Viewed products").count
        @product_views_today  = Ahoy::Event.where(name: "Viewed products").where(time: Time.current.all_day).count
        @unique_visitors_week = Ahoy::Visit.where(started_at: 7.days.ago..).count
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
