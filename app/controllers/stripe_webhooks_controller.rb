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

      order.order_items.includes(:variant).find_each do |item|
        item.variant.decrement!(:stock, item.quantity)
      end
      order.update!(status: "paid")

      # Can't use deliver_later; smth goes wrong & it never gets sent
      PurchaseSuccessMailer.successful_purchase(order).deliver_now

    elsif event.type == "checkout.session.expired"
      order = Order.find_by(stripe_session_id: event.data.object.id)
      return unless order
      return unless order.status == "pending"
      order.destroy
    end

    render plain: "OK", status: :ok
  end
end