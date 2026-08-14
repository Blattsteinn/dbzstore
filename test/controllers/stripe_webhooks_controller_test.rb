require "test_helper"
require "minitest/mock"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = Product.create!(
      title: "Webhook Product", visibility: "live", game_name: "dokkan",
      deliverables: "Account", payment_type: "stripe"
    )
    @variant = Variant.create!(product: @product, title: "Basic", price: 1000, stock: 5)
    @discount = Discount.create!(code: "WELCOME", amount: 5, percentage: 10, remaining: 2)
    @order = Order.create!(email: "buyer@example.com", status: "pending",
                           stripe_session_id: "cs_webhook_test", discount: @discount)
    @order.order_items.create!(product: @product, variant: @variant, quantity: 1, price: 900)
  end

  def completed_event
    object = Struct.new(:id).new(@order.stripe_session_id)
    data = Struct.new(:object).new(object)
    Struct.new(:type, :data).new("checkout.session.completed", data)
  end

  test "completed checkout marks order paid, decrements stock, redeems discount, enqueues mailers" do
    Stripe::Webhook.stub :construct_event, completed_event do
      assert_enqueued_emails 2 do
        assert_difference -> { @variant.reload.stock }, -1 do
          post stripe_webhooks_url
        end
      end
    end

    assert_response :ok
    assert @order.reload.paid?
    assert_equal 1, @discount.reload.remaining
  end

  test "completed checkout never decrements stock below zero" do
    @variant.update!(stock: 0)

    Stripe::Webhook.stub :construct_event, completed_event do
      assert_enqueued_emails 2 do
        post stripe_webhooks_url
      end
    end

    assert_response :ok
    assert @order.reload.paid?
    assert_equal 0, @variant.reload.stock
  end

  test "expired checkout destroys the pending order" do
    expired = Struct.new(:type, :data).new(
      "checkout.session.expired",
      Struct.new(:object).new(Struct.new(:id).new(@order.stripe_session_id)))

    Stripe::Webhook.stub :construct_event, expired do
      assert_difference "Order.count", -1 do
        post stripe_webhooks_url
      end
    end

    assert_response :ok
  end
end
