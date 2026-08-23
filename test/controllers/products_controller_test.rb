require "test_helper"
require "base64"
require "stringio"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Ahoy's bot detection (DeviceDetector) flags the default "Rails Testing"
  # user agent as a bot (no device type/OS), which silently drops tracking.
  BROWSER_UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  # 1×1 transparent PNG — enough for ActiveStorage + vips variant processing.
  PNG_1PX = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")

  setup do
    Game.create!(name: "dokkan")
    @product = Product.create!(
      title: "Test Product",
      deliverables: "static_value",
      payment_type: "single_payment",
      visibility: "live",
      game_name: "dokkan"
    )
  end

  def attach_image(product)
    pi = ProductImage.new(product: product)
    pi.image.attach(io: StringIO.new(PNG_1PX), filename: "image.png", content_type: "image/png")
    pi.save!
    pi
  end

  test "index renders live products and tracks an Ahoy event" do
    assert_difference "Ahoy::Event.count", 1 do
      get game_products_url("dokkan"), headers: { "User-Agent" => BROWSER_UA }
    end

    assert_response :ok
    assert_select "a.product-box", 1
  end

  test "hot products render the hot tag on the index" do
    Product.create!(title: "Hot Product", visibility: "live", game_name: "dokkan",
                    deliverables: "Account", payment_type: "stripe", hot: true)

    get game_products_url("dokkan"), headers: { "User-Agent" => BROWSER_UA }

    assert_response :ok
    assert_select ".hot-tag", 1
  end

  test "non-hot products do not render the hot tag" do
    get game_products_url("dokkan"), headers: { "User-Agent" => BROWSER_UA }

    assert_response :ok
    assert_select ".hot-tag", 0
  end

  test "storefront pages ship only storefront CSS and self-hosted fonts" do
    get game_products_url("dokkan"), headers: { "User-Agent" => BROWSER_UA }

    assert_response :ok
    assert_match %r{/assets/nav[^"']*\.css}, response.body
    assert_match %r{/assets/fonts[^"']*\.css}, response.body
    refute_match %r{/assets/dashboard[^"']*\.css}, response.body
    refute_match %r{fonts\.googleapis\.com|fonts\.gstatic\.com}, response.body
    assert_match %r{rel="preload"[^>]*inter[^>]*\.woff2}, response.body
  end

  test "show page gallery ships responsive srcset" do
    attach_image(@product)

    get game_product_url("dokkan", @product), headers: { "User-Agent" => BROWSER_UA }

    assert_response :ok
    assert_match %r{srcset="[^"]*600w, [^"]*1200w"}, response.body
  end

  test "show renders the carousel when a product has multiple images" do
    2.times { attach_image(@product) }

    get game_product_url("dokkan", @product), headers: { "User-Agent" => BROWSER_UA }

    assert_response :ok
    assert_match %r{carousel-counter[^>]*>1 / 2}, response.body
    assert_select ".carousel-dot", 2
  end

  test "show renders live product and tracks a product view event" do
    assert_difference "Ahoy::Event.count", 1 do
      get game_product_url("dokkan", @product), headers: { "User-Agent" => BROWSER_UA }
    end

    assert_response :ok

    event = Ahoy::Event.last
    assert_equal "Viewed product", event.name
    assert_equal @product.id, event.properties["product"]
    assert_equal @product.title, event.properties["title"]
    assert_equal @product.game_name, event.properties["game"]
  end

  test "admin dashboard ships dashboard.css" do
    admin = User.create!(email: "admin@example.com", password: "password", admin: true)
    sign_in admin

    get dashboard_url

    assert_response :ok
    assert_match %r{/assets/dashboard[^"']*\.css}, response.body
  end
end
