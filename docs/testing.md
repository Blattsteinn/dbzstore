# Testing

How to run and write tests, and the honest state of coverage.

## Running tests

```bash
bin/rails test                        # whole suite
bin/rails test test/controllers/orders_controller_test.rb   # single file
bin/rails test test/controllers/orders_controller_test.rb:12   # single test by line
```

The full CI gate (also runs tests) is `bin/ci` — see `config/ci.rb`.

## Current state (be honest about it)

- **Only two controller tests are real and comprehensive:**
  - `test/controllers/discounts_controller_test.rb` — admin/user/auth flows, CRUD, `remaining` defaults to `amount`, invalid params.
  - `test/controllers/orders_controller_test.rb` — checkout via stubbed Stripe (`Stripe::Checkout::Session.stub` with `minitest/mock`), honeypot, input validation, order + order_item creation, cancel flow, admin status update.
- **Everything else is an empty scaffold** (model tests, mailer tests, most controller tests just contain `# test "the truth"` comments). `test/integration/` is empty. There are **no system tests**.
- **Mailer previews**: `test/mailers/previews/purchase_success_mailer_preview.rb` is functional (uses `Order.joins(:order_items).last`); `to_self_mailer_preview.rb` is empty.

## Fixtures & data (read this before writing tests)

- `test_helper.rb` has **`fixtures :all` commented out** — fixtures are NOT loaded automatically.
- Most fixtures in `test/fixtures/` are empty templates (`one: {}`). Only `games.yml` has real data (`dokkan`, `legends`).
- **No factory gem** is installed.
- → The established pattern is to **create records inline in the test** (`Product.create!(...)`, `Order.create!(...)`, etc.). Follow that; don't assume fixtures exist.

## How to test the checkout without real Stripe

The orders test stubs the Stripe call so no network/keys are needed:

```ruby
session = Stripe::Checkout::Session.new(id: "cs_test_123", url: "https://checkout.stripe.com/...")
Stripe::Checkout::Session.stub(:create, session) do
  post orders_url, params: { email: "a@b.com", variant_id: variant.id, quantity: 1 }
end
```

Requires `minitest/mock` (in the test group of the Gemfile).

## Testing the webhook

`StripeWebhooksController` verifies signatures, so to test it you either:
- generate a real signature with `Stripe::Webhook` + a test secret, or
- stub `Stripe::Webhook.construct_event` to return a fabricated `event` object.

There is currently **no webhook test** — a good candidate to add. Cover: `checkout.session.completed` (stock decrement, `paid`, emails sent, discount redeemed, idempotency) and `checkout.session.expired` (pending order destroyed).

## Known bugs documented by tests

`orders_controller_test.rb` includes a test (*"cancel does not destroy a non-pending order"*) that documents a **known 500** — `OrdersController#cancel_stripe_checkout`'s else-branch (order not pending) redirects to `instructions_url`, but there's no template for that action rendering, causing a missing-template error. If you fix it, update the test to assert the expected behavior.

## Writing new tests: quick template

```ruby
require "test_helper"

class SomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "admin can do the thing" do
    admin = User.create!(email: "admin@x.com", password: "password", admin: true)
    sign_in admin
    # create inline records, then assert
  end
end
```
