class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  # skip_before_action :authenticate_user!

  def create
    payload    = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header,
        ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError
      render plain: "Invalid payload", status: :bad_request and return
    rescue Stripe::SignatureVerificationError
      render plain: "Invalid signature", status: :bad_request and return
    end

    if event.type == "checkout.session.completed"
      order = Order.find_by(stripe_session_id: event.data.object.id)
      return unless order
      return if order.paid?

      Order.transaction do
        order.order_items.includes(:variant).find_each do |item|
          if item.variant.stock >= item.quantity
            item.variant.decrement!(:stock, item.quantity)
          else
            Rails.logger.warn(
              "Insufficient stock for variant ##{item.variant.id} " \
              "(stock: #{item.variant.stock}, needed: #{item.quantity})")
          end
        end
        order.update!(status: "paid")
      end

      discount = Discount.create!(code: SecureRandom.alphanumeric(10).upcase, amount: 1, remaining: 1, percentage: 20);
      PurchaseSuccessMailer.successful_purchase(order, discount).deliver_later
      ToSelfMailer.mail_self(order).deliver_later
      order.discount&.redeem!

      # Dashboard aggregates are cached; drop them so the sale shows up promptly.
      DashboardController.invalidate_stats!

    elsif event.type == "checkout.session.expired"
      order = Order.find_by(stripe_session_id: event.data.object.id)
      return unless order
      return unless order.status == "pending"
      order.destroy
    end

    render plain: "OK", status: :ok
  end
end