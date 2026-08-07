# Security

The app's security model: authentication, authorization, spam protection, rate limiting, and Stripe webhook verification.

## Authentication (Devise)

- **Customers**: the storefront is **userless by design** — there is no global `authenticate_user!` (it's commented out in `ApplicationController`). Anyone can browse and buy.
- **Users** exist only for admin access. `User` uses Devise modules `database_authenticatable`, `recoverable`, `rememberable`, `validatable`. No confirmable/lockable/trackable.
- **Admin** is a plain boolean column `users.admin` (default `false`). There is **no UI or rake task to grant admin** — it's set directly in the DB.

## Authorization (`authenticate_admin!`)

Defined in `ApplicationController` (private):

```ruby
authenticate_user!            # Devise sign-in required
redirect_to root_path, alert: "You must be an admin" unless current_user.admin?
```

Applied via `before_action` to:
- `DashboardController` — **all** actions
- `ProductsController` — all except `index`/`show`
- `DiscountsController` — all except `check_discount`
- `FaqsController` — all except `index`
- `OrdersController` — `update`/`destroy` only (`create` is public checkout)
- `FeedbacksController` — `edit`/`update`/`destroy` only
- `SupportMessagesController` — `index`/`show`/`destroy`/`update` only

## Spam protection (honeypot)

`ApplicationController#honeypot_check` is a `before_action` on **`OrdersController#create`**, **`FeedbacksController#create`**, and **`SupportMessagesController#create`**:

```ruby
if params[:contact_me_by_fax_only].present?
  head :ok  # short-circuit, no side effects
end
```

The hidden field `contact_me_by_fax_only` is rendered off-screen in the purchase form. Humans never fill it; bots that auto-fill every field trip the trap and get a bare `200` with nothing happening. **Any new public form that posts to one of these endpoints must render this hidden field.**

## Rate limiting (Rack::Attack)

`config/initializers/rack_attack.rb` throttles abusive traffic per IP (and per email for orders):

| Throttle | Limit | Period | Trigger |
|---|---|---|---|
| `orders/ip` | 10 | 1 hour | `POST /orders` per IP |
| `orders/email` | 10 | 1 hour | `POST /orders` per email (downcased) — *"10 bcz stripe can be glitchy"* |
| `feedbacks/ip` | 5 | 1 hour | `POST /feedbacks` per IP |
| `support_messages/ip` | 3 | 1 hour | `POST /support_messages` per IP |
| `discount/check_discount` | 2 | 1 hour | `GET /discounts/check_discount` per IP — anti code-enumeration (AJAX) |

The `discount/check_discount` throttle matches `req.path == "/discounts/check_discount" && req.get?` (it's a **GET** endpoint, so `req.post?` would never fire). The frontend (`discount` Stimulus controller) treats any non-`ok` response as "too many attempts" and surfaces that to the shopper instead of silently failing.

## Stripe webhook verification

`POST /stripe/webhooks` → `StripeWebhooksController#create`:

- `skip_before_action :verify_authenticity_token` (no CSRF token — it's not a browser form).
- Signature verified with `Stripe::Webhook.construct_event(payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"])`.
- Returns `400 Bad Request` on `JSON::ParserError` or `Stripe::SignatureVerificationError`.
- Handlers are idempotent: `checkout.session.completed` returns early if the order is already `paid?`.

This is the **only unauthenticated state-changing endpoint** in the app — keep the signature check intact.

## Rails defaults in play

- `allow_browser versions: :modern` (Rails 8) — rejects old browsers.
- CSRF protection active everywhere else (`verify_authenticity_token` default).
- Content-Security-Policy initializer present (`config/initializers/content_security_policy.rb`).
- `filter_parameter_logging` present.
- Production: `assume_ssl` + `force_ssl`, hosts allowlist (`accountrift.com`, `*.accountrift.com`, `*.up.railway.app`).
- Dev/test gems `brakeman` + `bundler-audit` run in CI (`bin/ci`).

## Known security-adjacent notes

- `resources :discounts` exposes public `check_discount` (read-only, no decrement) — rate-limited to 2/hour/IP to deter code brute-forcing.
- The `admin` flag has no audit trail or escalation path; granting admin requires DB access anyway.
- No rate limit on admin sign-in beyond Devise defaults (no `lockable`).
