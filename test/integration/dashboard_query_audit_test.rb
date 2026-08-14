require "test_helper"

class DashboardQueryAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "audit-admin@example.com", password: "password", admin: true)
    sign_in @admin

    # Representative data for each dashboard page
    products = 12.times.map do |i|
      Product.create!(
        title: "Audit Product #{i}", visibility: "live", game_name: "dokkan",
        deliverables: "Account", payment_type: "stripe"
      ).tap do |p|
        2.times { |j| Variant.create!(product: p, title: "V#{j}", price: 5000 + i * 100, stock: 10) }
      end
    end
    @product = products.first
    @variant = @product.variants.first
    15.times do |i|
      order = Order.create!(email: "buyer#{i}@example.com", status: %w[pending paid paid delivered].sample, discord: "d#{i}")
      order.order_items.create!(product: products.sample, variant: products.sample.variants.sample, price: 7199, quantity: 1)
      Feedback.create!(order: order, rating: (1..5).to_a.sample, feedback: "Audit feedback #{i}")
    end
    @order = Order.first
    @orphan_order = Order.create!(email: "orphan@example.com", status: "pending", discord: "x")
    orphan_item = @orphan_order.order_items.create!(product: @product, variant: @variant, price: 599, quantity: 1)
    # Simulate dependent: :nullify after product/variant deletion (bypasses belongs_to validation)
    orphan_item.update_columns(product_id: nil, variant_id: nil)
    Discount.create!(code: "AUDIT", amount: 5, percentage: 10, remaining: 5)
    Faq.create!(question: "Q", answer: "A")
    25.times do |i|
      v = Ahoy::Visit.create!(started_at: i.hours.ago, visitor_token: "tok#{i}", ip: "1.2.3.#{i % 250}", user_agent: "Chrome")
      Ahoy::Event.create!(visit: v, name: "Viewed products", time: i.hours.ago, properties: {})
    end
    Ahoy::Event.create!(visit: Ahoy::Visit.first, name: "Viewed product", time: 1.hour.ago,
                        properties: { product: @product.id, title: @product.title, game: "dokkan" })
  end

  test "dashboard pages stay within bounded query counts (no N+1)" do
    # Page => max allowed SQL queries. Baselines are ~5-13; an N+1 with the
    # setup data below adds ~15-25 queries and blows past the ceiling.
    ceilings = {
      "overview"       => ["/dashboard", 20],
      "orders_index"   => ["/dashboard/orders", 20],
      "order_show"     => ["/dashboard/orders/#{@order.id}", 12],
      "order_orphan"   => ["/dashboard/orders/#{@orphan_order.id}", 10],
      "products"       => ["/dashboard/productss", 12],
      "feedback_index" => ["/dashboard/feedback_index", 12],
      "feedback_show"  => ["/dashboard/feedback_show/#{Feedback.first.id}", 10],
      "visitors"       => ["/dashboard/visitors", 12],
      "product_views"  => ["/dashboard/product_views", 14],
      "discounts"      => ["/dashboard/discount_index", 12],
      "faqs"           => ["/dashboard/faq_index", 12]
    }

    ceilings.each do |label, (path, ceiling)|
      queries = []
      counter = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get path
        assert_response :success, "#{label} failed: #{response.status}"
      end
      assert queries.size <= ceiling,
             "#{label} (#{path}) made #{queries.size} SQL queries (ceiling #{ceiling}) — possible N+1"
    end
  end
end
