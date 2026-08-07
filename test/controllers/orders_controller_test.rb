require "test_helper"
require "test_helper"
require "minitest/mock"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @product = Product.create!(
      title: "Test Product",
      description: "A test description",
      deliverables: "static_value",
      payment_type: "single_payment",
      visibility: "live",
      game_name: "dokkan"
    )
    @variant = Variant.create!(product: @product, title: "Basic", price: 1000, stock: 5)
    @email = "buyer@example.com"
  end

  # ---------------------------------------------------------------
  # POST /orders (create)
  # ---------------------------------------------------------------
  test "discord param is registered" do
    fake_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub :create, ->(params) { fake_session } do
      assert_difference ["Order.count", "OrderItem.count"], 1 do
        post orders_url, params: {
          email: @email,
          variant_id: @variant.id,
          quantity: 1,
          discord: "DiscordName"
        }
      end
    end

    order = Order.last
    assert_equal @email, order.email
    assert_equal order.discord, "DiscordName"
  end

  test "honeypot field blocks the request without creating an order" do
    assert_no_difference ["Order.count", "OrderItem.count"] do
      post orders_url, params: {
        contact_me_by_fax_only: "spam",
        email: @email,
        variant_id: @variant.id,
        quantity: 1
      }
    end

    assert_response :ok
  end

  test "invalid email redirects to products with an alert" do
    assert_no_difference "Order.count" do
      post orders_url, params: { email: "not-an-email", variant_id: @variant.id, quantity: 1 }
    end

    assert_redirected_to products_path
    assert_equal "Wrong inputs", flash[:alert]
  end

  test "missing variant_id redirects to products with an alert" do
    assert_no_difference "Order.count" do
      post orders_url, params: { email: @email, quantity: 1 }
    end

    assert_redirected_to products_path
    assert_equal "Wrong inputs", flash[:alert]
  end

  test "missing quantity redirects to products with an alert" do
    assert_no_difference "Order.count" do
      post orders_url, params: { email: @email, variant_id: @variant.id }
    end

    assert_redirected_to products_path
    assert_equal "Wrong inputs", flash[:alert]
  end

  test "any quantity of not 1 redirects to products with an invalid quantity alert" do
    assert_no_difference "Order.count" do
      post orders_url, params: { email: @email, variant_id: @variant.id, quantity: 2 }
    end

    assert_redirected_to games_path
    assert_equal "Invalid quantity", flash[:alert]
  end

  test "quantity below 1 redirects to products with an invalid quantity alert" do
    assert_no_difference "Order.count" do
      post orders_url, params: { email: @email, variant_id: @variant.id, quantity: 0 }
    end

    assert_redirected_to games_path
    assert_equal "Invalid quantity", flash[:alert]
  end

  test "unknown variant_id redirects to products with an invalid product alert" do
    assert_no_difference "Order.count" do
      post orders_url, params: { email: @email, variant_id: 999_999, quantity: 1 }
    end

    assert_redirected_to games_path
    assert_equal "Invalid product", flash[:alert]
  end

  test "valid params create an order and order item, then redirect to stripe" do
    fake_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/pay/cs_test_123")
    captured = nil

    Stripe::Checkout::Session.stub :create, ->(params) { captured = params; fake_session } do
      assert_difference ["Order.count", "OrderItem.count"], 1 do
        post orders_url, params: { email: @email, variant_id: @variant.id, quantity: 1 }
      end
    end

    order = Order.last
    assert_equal @email, order.email
    assert_equal "pending", order.status
    assert_equal "cs_test_123", order.stripe_session_id
    assert order.public_id.present?

    item = order.order_items.first
    assert_equal @variant.id, item.variant_id
    assert_equal @product.id, item.product_id
    assert_equal 1, item.quantity
    assert_equal @variant.price, item.price

    # The Stripe session was configured with the right payload.
    assert_equal "payment", captured[:mode]
    assert_equal @email, captured[:customer_email]
    assert_equal order.id.to_s, captured[:client_reference_id]
    assert_equal @variant.price, captured[:line_items].first[:price_data][:unit_amount]

    assert_redirected_to "https://checkout.stripe.com/pay/cs_test_123"
  end

  # ---------------------------------------------------------------
  # POST /orders (create) — purchase with a discount code
  # ---------------------------------------------------------------

  test "valid params with a discount code apply the discount to the order and the price" do
    discount = Discount.create!(code: "SAVE20", amount: 10, remaining: 5, percentage: 20)
    fake_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/pay/cs_test_123")
    captured = nil

    Stripe::Checkout::Session.stub :create, ->(params) { captured = params; fake_session } do
      assert_difference ["Order.count", "OrderItem.count"], 1 do
        post orders_url, params: {
          email: @email,
          variant_id: @variant.id,
          quantity: 1,
          code: "SAVE20"
        }
      end
    end

    order = Order.last
    assert_equal discount.id, order.discount_id
    assert_equal 20, order.discount_percentage

    # 20% off a 1000 price variant -> 800, reflected both on the order item
    # and in the Stripe session line item.
    assert_equal 800, order.order_items.first.price
    assert_equal 800, captured[:line_items].first[:price_data][:unit_amount]
  end

  test "an unknown discount code is ignored and the order keeps the full price" do
    fake_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub :create, ->(params) { fake_session } do
      assert_difference ["Order.count", "OrderItem.count"], 1 do
        post orders_url, params: {
          email: @email,
          variant_id: @variant.id,
          quantity: 1,
          code: "DOES_NOT_EXIST"
        }
      end
    end

    order = Order.last
    assert_nil order.discount_id
    assert_equal 0, order.discount_percentage
    assert_equal @variant.price, order.order_items.first.price
  end

  test "a missing discount code is ignored and the order keeps the full price" do
    fake_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub :create, ->(params) { fake_session } do
      assert_difference ["Order.count", "OrderItem.count"], 1 do
        post orders_url, params: {
          email: @email,
          variant_id: @variant.id,
          quantity: 1
        }
      end
    end

    order = Order.last
    assert_nil order.discount_id
    assert_equal 0, order.discount_percentage
    assert_equal @variant.price, order.order_items.first.price
  end

  test "an exhausted discount code is ignored at order time and the order keeps the full price" do
    Discount.create!(code: "GONE", amount: 10, remaining: 0, percentage: 20)
    fake_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub :create, ->(params) { fake_session } do
      assert_difference ["Order.count", "OrderItem.count"], 1 do
        post orders_url, params: {
          email: @email,
          variant_id: @variant.id,
          quantity: 1,
          code: "GONE"
        }
      end
    end

    order = Order.last
    assert_nil order.discount_id
    assert_equal 0, order.discount_percentage
    assert_equal @variant.price, order.order_items.first.price
  end

  # ---------------------------------------------------------------
  # GET /orders/:public_id/cancel (cancel_stripe_checkout)
  # ---------------------------------------------------------------

  test "cancel with an unknown public_id returns 404" do
    get cancel_stripe_checkout_order_url(public_id: "DOES_NOT_EXIST")
    assert_response :not_found
  end

  test "cancel destroys a pending order and redirects" do
    order = Order.create!(email: @email)
    OrderItem.create!(order: order, product: @product, variant: @variant, quantity: 1, price: @variant.price)

    assert_difference "Order.count", -1 do
      get cancel_stripe_checkout_order_url(public_id: order.public_id)
    end

    assert_redirected_to game_products_path(@product.game_name)
    assert_equal "Payment was cancelled", flash[:alert]
  end

  test "cancel does not destroy a non-pending order" do
    order = Order.create!(email: @email, status: "paid")

    assert_no_difference "Order.count" do
      get cancel_stripe_checkout_order_url(public_id: order.public_id)
    end

    # NOTE: this currently raises ActionView::MissingTemplate (500) because the
    # action returns without redirecting/rendering for non-pending orders.
    # Add an else branch that redirects (e.g. to the order/game page).
    assert_redirected_to instructions_path
  end

  # ---------------------------------------------------------------
  # PATCH /orders/:id (update) — admin only
  # ---------------------------------------------------------------

  test "update redirects unauthenticated visitors to sign in" do
    order = Order.create!(email: @email)

    patch order_url(order), params: { order: { status: "paid" } }

    assert_redirected_to new_user_session_path
    assert_equal "pending", order.reload.status
  end

  test "update blocks non-admin users" do
    sign_in User.create!(email: "user@example.com", password: "password123")
    order = Order.create!(email: @email)

    patch order_url(order), params: { order: { status: "paid" } }

    assert_redirected_to root_path
    assert_equal "You must be an admin", flash[:alert]
    assert_equal "pending", order.reload.status
  end

  test "admin can update the order status" do
    sign_in User.create!(email: "admin@example.com", password: "password123", admin: true)
    order = Order.create!(email: @email)

    patch order_url(order), params: { order: { status: "paid" } }

    assert_redirected_to dashboard_order_path(order)
    assert_equal "paid", order.reload.status
  end

  # ---------------------------------------------------------------
  # DELETE /orders/:id (destroy) — admin only
  # ---------------------------------------------------------------

  test "destroy redirects unauthenticated visitors to sign in" do
    order = Order.create!(email: @email)

    delete order_url(order)

    assert_redirected_to new_user_session_path
    assert Order.exists?(order.id)
  end

  test "admin can destroy an order" do
    sign_in User.create!(email: "admin@example.com", password: "password123", admin: true)
    order = Order.create!(email: @email)

    assert_difference "Order.count", -1 do
      delete order_url(order)
    end

    assert_redirected_to dashboard_orders_path
  end
end
