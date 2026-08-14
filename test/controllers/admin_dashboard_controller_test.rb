require "test_helper"

class AdminDashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin@example.com", password: "password123", admin: true)
    @user  = User.create!(email: "user@example.com", password: "password123")

    @product = Product.create!(title: "Dash Product", visibility: "live", game_name: "dokkan",
                               deliverables: "Account", payment_type: "stripe")
    @variant = Variant.create!(product: @product, title: "Basic", price: 1000, stock: 5)
    @order = Order.create!(email: "buyer@example.com", status: "paid", discord: "discordname")
    @order.order_items.create!(product: @product, variant: @variant, quantity: 1, price: 1000)
    @feedback = Feedback.create!(order: @order, rating: 5, feedback: "Amazing service, very fast!")
    @faq = Faq.create!(question: "Question?", answer: "Answer.")
    @discount = Discount.create!(code: "DASH10", amount: 10, percentage: 10, remaining: 5)
    Ahoy::Visit.create!(started_at: 1.hour.ago, visitor_token: "visitor-1", ip: "1.2.3.4")
    SupportMessage.create!(title: "Help", email: "buyer@example.com",
                           message: "I need help with my order please.", order: @order)
  end

  # ---------------------------------------------------------------
  # Auth — every dashboard action requires an admin
  # ---------------------------------------------------------------

  test "every dashboard action redirects unauthenticated visitors to sign in" do
    dashboard_paths.each do |path|
      get path
      assert_redirected_to new_user_session_path
    end
  end

  test "every dashboard action blocks non-admin users" do
    sign_in @user

    dashboard_paths.each do |path|
      get path
      assert_redirected_to root_path
      assert_equal "You must be an admin", flash[:alert]
    end
  end

  private

  def dashboard_paths
    [
      dashboard_url,
      dashboard_products_url,
      dashboard_orders_url,
      dashboard_order_url(@order),
      dashboard_feedbacks_url,
      dashboard_feedback_show_url(@feedback),
      dashboard_faqs_url,
      dashboard_visitors_url,
      dashboard_discounts_url
    ]
  end

  # ---------------------------------------------------------------
  # GET /dashboard (index)
  # ---------------------------------------------------------------

  test "admin can view the dashboard overview with stats" do
    sign_in @admin
    get dashboard_url

    assert_response :ok
    assert_match /10\.0/, response.body # revenue: 1000 cents
    assert_match /Total Orders/, response.body
    assert_match /buyer@example\.com/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/productss (products_index)
  # ---------------------------------------------------------------

  test "admin can view dashboard products" do
    sign_in @admin
    get dashboard_products_url

    assert_response :ok
    assert_match /Dash Product/, response.body
  end

  test "admin can filter dashboard products by game" do
    sign_in @admin
    get dashboard_products_url, params: { game_name: "dokkan" }

    assert_response :ok
    assert_match /Dash Product/, response.body
  end

  test "dashboard products filter excludes other games" do
    Product.create!(title: "Other Game Product", visibility: "live", game_name: "legends",
                    deliverables: "Account", payment_type: "stripe")
    sign_in @admin
    get dashboard_products_url, params: { game_name: "dokkan" }

    assert_response :ok
    assert_match /Dash Product/, response.body
    refute_match /Other Game Product/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/orders (orders_index)
  # ---------------------------------------------------------------

  test "admin can view dashboard orders" do
    sign_in @admin
    get dashboard_orders_url

    assert_response :ok
    assert_match /Dash Product/, response.body
    assert_match /buyer@example\.com/, response.body
  end

  test "admin can filter dashboard orders by status" do
    pending = Order.create!(email: "pending@example.com", status: "pending")
    sign_in @admin
    get dashboard_orders_url, params: { status: [ "paid" ] }

    assert_response :ok
    assert_match /buyer@example\.com/, response.body
    refute_match /pending@example\.com/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/orders/:id (order_show)
  # ---------------------------------------------------------------

  test "admin can view a single order" do
    sign_in @admin
    get dashboard_order_url(@order)

    assert_response :ok
    assert_match /Dash Product/, response.body
    assert_match /buyer@example\.com/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/feedback_index (feedback_index)
  # ---------------------------------------------------------------

  test "admin can view dashboard feedback" do
    sign_in @admin
    get dashboard_feedbacks_url

    assert_response :ok
    assert_match /Amazing service, very fast!/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/feedback_show/:id (feedback_show)
  # ---------------------------------------------------------------

  test "admin can view a single feedback" do
    sign_in @admin
    get dashboard_feedback_show_url(@feedback)

    assert_response :ok
    assert_match /Amazing service, very fast!/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/faq_index (faq_index)
  # ---------------------------------------------------------------

  test "admin can view dashboard faqs" do
    sign_in @admin
    get dashboard_faqs_url

    assert_response :ok
    assert_match /Question\?/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/visitors (visitors)
  # ---------------------------------------------------------------

  test "admin can view dashboard visitors" do
    sign_in @admin
    get dashboard_visitors_url

    assert_response :ok
    assert_match /1\.2\.3\.4/, response.body
  end

  # ---------------------------------------------------------------
  # GET /dashboard/discount_index (discount_index)
  # ---------------------------------------------------------------

  test "admin can view dashboard discounts" do
    sign_in @admin
    get dashboard_discounts_url

    assert_response :ok
    assert_match /DASH10/, response.body
  end

  # ---------------------------------------------------------------
  # DashboardController.invalidate_stats!
  # ---------------------------------------------------------------

  test "invalidate_stats! clears the dashboard cache keys without error" do
    # Test env uses a :null_store cache, so this is a smoke test — it exercises
    # delete_multi over every CACHE_KEYS entry and would catch typos/regressions.
    assert_nothing_raised do
      DashboardController.invalidate_stats!
    end

    DashboardController::CACHE_KEYS.each do |key|
      assert_nil Rails.cache.read(key)
    end
  end
end
