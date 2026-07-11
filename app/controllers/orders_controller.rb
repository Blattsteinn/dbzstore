require "stripe"

class OrdersController < ApplicationController
    # pending, paid, processing, delivered, cancelled, refunded.
    before_action :honeypot_check, only: [:create]
    before_action :authenticate_admin!, only: [ :update, :destroy ]

    def create
        valid = params[:email].match?(URI::MailTo::EMAIL_REGEXP) &&
            params[:variant_id].present? &&
            params[:quantity].present?
        
        unless valid
            redirect_to products_path, alert: "Wrong inputs"
            return
        end

        @discord  = params[:discord]
        @email    = params[:email]
        @variant  = Variant.includes(:product).find_by(id: params[:variant_id].to_i)
        @quantity = params[:quantity].to_i

        unless @variant
            redirect_to products_path, alert: "Invalid product"
            return
        end

        # --- Reserve stock atomically to prevent race conditions ---
        stock_reserved = false

        ActiveRecord::Base.transaction do
            @variant.with_lock do
                if @variant.stock >= @quantity
                    @variant.decrement!(:stock, @quantity)
                    stock_reserved = true
                end
            end

            raise ActiveRecord::Rollback unless stock_reserved

            @order = Order.create!(email: @email, discord: @discord)
            OrderItem.create!(
                order_id: @order.id,
                product_id: @variant.product_id,
                variant_id: @variant.id,
                quantity: @quantity,
                price: @variant.price,
            )
        end

        unless stock_reserved
            redirect_to game_product_path(game: @variant.product.game_name, id: @variant.product), alert: "Not enough stock available"
            return
        end

        # --- Set-up for Stripe ---
        line_items = @order.order_items.map do |item|
        {   quantity: item.quantity,
            price_data: { currency: "eur", unit_amount: item.price,
                        product_data: { name: @variant.product.title + " (#{@variant.title })"} } }
        end

        # === Stripe session thing ===
        stripe_session = Stripe::Checkout::Session.create(
            mode: "payment",
            line_items: line_items,
            customer_email: @email,
            client_reference_id: @order.id.to_s,
            success_url: instructions_url,
            cancel_url: cancel_stripe_checkout_order_url(public_id: @order.public_id)
        )

        @order.update!(stripe_session_id: stripe_session.id)
        redirect_to stripe_session.url, allow_other_host: true

        rescue Stripe::StripeError => e
            if @order
                @order.restore_stock!
                @order.destroy
            end
            redirect_to product_path(@variant.product), alert: "Payment could not be initiated: #{e.message}"
    end

    # DEFINED in stripe_session = Stripe::Checkout::Session.create (look above)
    def cancel_stripe_checkout
        @order = Order.find_by!(public_id: params[:public_id])

        #we cant cancel completed order
        if @order.status == "paid"
            return
        end

        if @order.status == "pending"
            @order.restore_stock!
            @order.destroy
            redirect_to products_path, notice: "Checkout cancelled."
        else
            redirect_to products_path, alert: "This order cannot be cancelled."
        end
    end


    def update
        @order = Order.find(params[:id])
        @order.update!(update_params)
        redirect_to dashboard_order_path(@order)
    end

    def destroy
        @order = Order.find(params[:id])
        @order.destroy
        redirect_to dashboard_orders_path
    end

    private
    def update_params
        params.expect(order: [ :status ])
    end

    def order_params
     params.expect(order: [:product_id, :variant_id, :quantity, :price, :discord ])
    end
end
