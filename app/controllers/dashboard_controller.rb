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
        render "dashboard/product/products_index"
    end

    def orders_index
        @orders = Order.includes(order_items: [:product, :variant]).all.order(created_at: :desc)
        @orders = @orders.where(status: params[:status]) if params[:status].present?
        render "dashboard/order/orders_index"
    end

    def order_show
        @order = Order.includes(order_items: [:product, :variant]).find(params[:id])
        render "dashboard/order/order_show"
    end

    def feedback_index
        @feedbacks = Feedback.all
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
        # @pagy, @records = pagy(:offset, Product.some_scope, **options)
        @pagy, @visits = pagy(:offset, Ahoy::Visit.includes(:events)
                              .order(started_at: :desc), limit: 20)
    end

    private

    def set_open_support
        @open_support = SupportMessage.where(status: "open").count
    end

end
