# AGENTS.md — dbzstore ("Account Rift")

Project orientation for AI agents, future-self, and anyone joining the codebase.
This file is the **map** — read it before opening files. Deep dives live in [`docs/`](docs/README.md) and are linked inline below.

## What this is

A **userless e-commerce storefront** for game accounts/items, built with Ruby on Rails 8.1. Customers buy instantly (no account needed), pay via **Stripe Checkout**, and the shop owner fulfills orders from an **admin dashboard**. Email is sent via Resend. Analytics via Ahoy + MaxMind geolocation.

- Rails module: `AccountRift` (see `config/application.rb`)
- Rails `8.1.2`, Ruby `3.3.6`, PostgreSQL, Hotwire (Turbo + Stimulus) with importmap
- Puma + Solid Queue/Cache/Cable (all backed by Postgres in production)
- Deploy: Kamal + Docker (`Dockerfile`, `bin/docker-entrypoint`); production host `accountrift.com`

## Commands (run these)

```bash
bin/setup                # bundle install + db:prepare (+ --reset, --skip-server)
bin/dev                  # run the Rails server (port 3000)
bin/rails server         # same, explicit

bin/rails test           # run the test suite
bin/rails test test/controllers/orders_controller_test.rb   # single file
bin/ci                   # full pipeline: rubocop → bundler-audit → importmap audit → brakeman → test → db:seed:replant

bin/rubocop              # style (rubocop-rails-omakase)
bin/brakeman             # security scan
bin/bundler-audit        # gem vulnerabilities
bin/rails db:prepare     # create/migrate
bin/rails db:seed        # seed data
bin/rails routes         # dump routes
```

`bin/ci` steps are defined in `config/ci.rb`. On Docker start, `bin/docker-entrypoint` runs `db:prepare` automatically.

## Environment variables

There is **no `.env.example` committed** — see [`docs/setup.md`](docs/setup.md#environment-variables) for the full list. Critical ones:

| Var | Used by |
|---|---|
| `STRIPE_SECRET_KEY` | `config/initializers/stripe.rb` |
| `STRIPE_WEBHOOK_SECRET` | `StripeWebhooksController` (signature verification) |
| `RESEND_API_KEY` | `config/initializers/resend.rb` |
| `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_ACCESS_KEY_ID`, `CLOUDFLARE_SECRET_ACCESS_KEY`, `CLOUDFLARE_BUCKET` | `config/storage.yml` (R2/S3 production storage) |
| `DATABASE_URL` | `config/database.yml` (production only) |
| `RAILS_MASTER_KEY` | Kamal/Docker secrets |

`dotenv-rails` is loaded in dev/test, so a local `.env` works there.

## Architecture at a glance

```
Storefront (userless)          Admin (Devise + admin flag)
  Games / Products / Variants    DashboardController (products, orders,
  Instant checkout via Stripe       feedback, faqs, discounts, visitors)
  Feedback / Support messages    Product/Discount/Faq/Feedback/SupportMessage CRUD
                                 StripeWebhooksController (payment confirmation)
```

- **No cart, no wishlist, no user checkout.** The storefront is intentionally userless (`authenticate_user!` is commented out globally). `cart_items` / `wish_lists` tables exist in the schema but have **no models, controllers, or views** — legacy, do not assume cart functionality exists.
- Products are scoped to games by a **`game_name` string column** (not an FK). Routing pattern: `/:game/products` → e.g. `/dokkan/products`.
- **Money is stored in cents (integer)**. Stripe `unit_amount` = the stored integer. Views convert via `convert_from_cents` helper.

## File map — read this instead of opening files

### Models (`app/models/`)

| File | Contents |
|---|---|
| `product.rb` | `has_many` images/variants/order_items/localized_descriptions; `visible` scope (`visibility: "live"`); `primary_image`, `thumbnail` (600×600 webp); nested attrs for images/variants/localized descriptions |
| `variant.rb` | belongs_to product; price (cents) + stock; no price validation |
| `game.rb` | **Empty** — just `name` (unique) + `official_name` columns |
| `order.rb` | statuses `pending paid processing delivered cancelled refunded`; `before_validation :generate_public_id` (20-char upcased alphanumeric); `paid?`; belongs_to user/discount (optional) |
| `order_item.rb` | belongs_to order/product/variant; stores `price` at purchase time (snapshot) |
| `discount.rb` | `available?`, **`redeem!`** (decrements `remaining`); `create` sets `remaining = amount`; `percentage` NOT validated |
| `feedback.rb` | one per order (uniqueness on order); rating 1..5 |
| `support_message.rb` | belongs_to order; status `open` default |
| `faq.rb` | plain question/answer |
| `user.rb` | Devise (`database_authenticatable`, `recoverable`, `rememberable`, `validatable`); admin is a **plain boolean column**; `welcome_email` callback commented out |
| `product_image.rb` | `has_one_attached :image` |
| `language.rb` / `localized_description.rb` | per-language product descriptions (unique per product+language) |
| `ahoy/visit.rb` | geocodes IP on create (GeoIP2 via Geocoder) — sets country/city/region/lat/long |
| `ahoy/event.rb` | standard Ahoy event |
| `concerns/` | **empty** (only `.keep`) |

### Controllers (`app/controllers/`)

| File | Key behavior |
|---|---|
| `application_controller.rb` | `include Pagy::Method`; `authenticate_admin!` (sign-in + `admin?`, else redirect root with "You must be an admin"); **`honeypot_check`** — if `params[:contact_me_by_fax_only]` present, `head :ok` and short-circuit (spam trap) |
| `products_controller.rb` | `index` (visible products filtered by `params[:game]`, ordered by priority, tracks Ahoy view) / `show` (any visibility but redirects unless live; hardcoded contact markdown `@text`) / admin CRUD + `product_visibility` toggle (live↔hidden) + `duplicate_product` (deep-copy + variants, appends " Copy"). **Dead code:** `show_hero/minimal/split/card/gallery` |
| `orders_controller.rb` | **Checkout endpoint.** `create`: honeypot → validate email/variant/quantity → `set_discount(params[:code])` (returns `[discount_id, percentage]`, or `[nil, 0]` for unknown **or exhausted** codes) → `Order.create!` (pending) → `OrderItem` with discounted price → build Stripe Checkout Session → redirect to Stripe. `cancel_stripe_checkout` (GET `orders/:public_id/cancel`) destroys pending orders. Admin `update` (status) / `destroy`. See [`docs/flows.md`](docs/flows.md#checkout-flow) |
| `stripe_webhooks_controller.rb` | `POST /stripe/webhooks`, CSRF skipped, **no auth**, signature-verified. `checkout.session.completed` → decrement stock, `status: paid`, send mailers `deliver_now`, `discount.redeem!`. `checkout.session.expired` → destroy pending order. See [`docs/flows.md`](docs/flows.md#stripe-webhook) |
| `dashboard_controller.rb` | `authenticate_admin!` everywhere. `index` (revenue cached 1h from paid orders, order stats, Ahoy stats), `products_index`, `orders_index` (status filter), `order_show`, `feedback_index/show`, `faq_index`, `visitors` (Pagy 20), `discount_index` |
| `discounts_controller.rb` | Admin CRUD + public **`check_discount`** JSON endpoint (`{valid:, percentage:}` — does NOT decrement). `create` sets `remaining = amount`. `check_discount` is rate-limited 2/hr/IP (see [`docs/security.md`](docs/security.md#rate-limiting-rackattack)) |
| `feedbacks_controller.rb` | Public `index` (Pagy 10) + `new/create` keyed by **order `public_id`**; admin `edit/update/destroy` |
| `support_messages_controller.rb` | Public `new/create` (keyed by order `public_id`); admin `index/show/update(status)/destroy` (destroy has no redirect) |
| `faqs_controller.rb` | Public `index`; admin CRUD (admin index is actually served by dashboard) |
| `games_controller.rb` | `index` only — `Game.all` + `fresh_when` |
| `instructions_controller.rb` | Action named `instructions` (not `index`) — shows delivery/instructions page |
| `privacy_controller.rb`, `tos_controller.rb` | Bare static pages |
| `concerns/` | **empty** (only `.keep`) |

### Helpers, Mailers, Jobs

- `app/helpers/products_helper.rb` — **the only real helper**: `MARKDOWN_RENDERER` (Redcarpet, sanitized, autolinks, tables), `convert_from_cents(cents)`, `markdown(text)`. All other helpers are empty modules.
- `app/mailers/` — `ApplicationMailer` (from `noreply@accountrift.com`); `PurchaseSuccessMailer#successful_purchase` (to customer, "Order {public_id} delivery"); `ToSelfMailer#mail_self` (to owner, "Order received, {price} EUR"); `UserMailer#welcome_email` (**not called** — commented out).
- `app/jobs/` — only `ApplicationJob`. **No jobs exist.** Mailers are sent synchronously from the webhook (see Gotchas #3).

### Frontend (`app/javascript/controllers/` — Stimulus, importmap)

| Controller | Purpose |
|---|---|
| `checkout_form_controller.js` | Purchase form submit → shows `#stripe-loading-overlay`, honors HTML5 validation |
| `discount_controller.js` | Fetches `check_discount?code=` JSON, applies `% off` to prices, injects code into form; shows "Checking code…" loading state (spinner) while fetching and locks input/button during the request |
| `product_view_controller.js` | Image carousel + lightbox, variant selection, quantity +/- capped at stock, EUR price display |
| `language_switcher_controller.js` / `_instructions_controller.js` | Language dropdown toggles per-language description divs |
| `insert_variant_controller.js`, `insert_image_controller.js` | Admin product form dynamic rows (clone templates `NEW_RECORD` / `NEW_IMAGE`) |
| `clipboard_controller.js`, `collapse_controller.js` | Copy-to-clipboard, accordion |
| `nav_controller.js` | Site nav (layout `nav.site-nav`): mobile hamburger + games dropdown; closes on outside click/Escape |
| `price_controller.js`, `hello_controller.js` | **Legacy/unused** (no cart UI; scaffold) |

### Config (`config/`)

- `routes.rb` — see the quirks in Gotchas #1–2. Key routes: `/:game/products`, `resources :orders` (only create/destroy/update), `GET orders/:public_id/cancel`, `POST stripe/webhooks`, `dashboard/*`, root redirects to `/dokkan/products`.
- `initializers/stripe.rb`, `resend.rb`, `ahoy.rb` (JS tracking OFF, geocode OFF — geocoding manual in model), `geocoder.rb` (GeoIP2 MaxMind DB at `vendor/GeoLite2-Country.mmdb`), `rack_attack.rb` (throttles, see [`docs/security.md`](docs/security.md)).
- `database.yml` — Postgres; production uses 4 connections (primary/cache/queue/cable) all from `DATABASE_URL`.
- `storage.yml` — disk in dev/test, **Cloudflare R2 (S3-compatible)** in production.
- `deploy.yml` (Kamal), `recurring.yml` (hourly SolidQueue cleanup @ minute 12, prod only), `queue.yml`/`cache.yml`/`cable.yml`, `puma.rb` (solid_queue plugin when `SOLID_QUEUE_IN_PUMA`).

## Key domain flows

Full diagrams + detail in [`docs/flows.md`](docs/flows.md). Short version:

- **Checkout**: form (variant, qty=1, email, optional code, honeypot) → `OrdersController#create` → `Order` (pending) + `OrderItem` (discounted price in cents) → Stripe Checkout Session (EUR, `success_url: instructions_url`, cancel → `cancel_stripe_checkout`) → redirect to Stripe.
- **Payment confirmed**: Stripe webhook `checkout.session.completed` → decrement variant stock → `status: paid` → `PurchaseSuccessMailer` + `ToSelfMailer` (`deliver_now`) → `discount.redeem!`.
- **Order lifecycle**: `pending → paid → processing → delivered` (admin sets via dashboard) / `cancelled` / `refunded`.
- **Discount**: created with `remaining = amount`; `check_discount` returns validity + percentage; only redeemed at webhook time.

## Gotchas — read before changing code

1. **`dashboard/productss` typo route is load-bearing.** The URL path is `/dashboard/productss` but the helper `dashboard_products_path` is used in ~10 places. Do not "fix" the path without updating all callers.
2. **`resources :discounts` has no `:index`/`:show` GET routes**, but `DiscountsController#destroy` redirects to `discounts_path` (undefined) — a **latent bug**. Don't silently refactor; note it if touched.
3. **Mailers are sent with `deliver_now` from the Stripe webhook, not `deliver_later`.** Code comment: *"Can't use deliver_later; smth goes wrong & it never gets sent."* Do not "fix" this to async without verifying delivery works.
4. **Cart/wishlist tables (`cart_items`, `wish_lists`) are schema-only** — no models/controllers/views. Don't assume cart functionality exists.
5. **Money is in cents.** `OrderItem#price`, `Variant#price` are integer cents. Never treat as dollars.
6. **Discount redemption happens only in the webhook** (`order.discount&.redeem!`). `check_discount` never decrements. Both `check_discount` and order-time `set_discount` check `available?` — exhausted codes are never applied.
7. **Storefront is userless by design.** `authenticate_user!` is commented out globally. Admin is a plain `admin` boolean on `users`.
8. **Order `quantity` is always 1 by design** (comment: *"It sure does add more headache now, but it's easier to keep it that way"*). No race-condition handling by design.
9. **Known bug**: `cancel_stripe_checkout`'s else-branch (non-pending order) hits a missing template (documented in `orders_controller_test.rb`).
10. **Honeypot spam trap**: any form posting to orders/feedbacks/support_messages must include hidden field `contact_me_by_fax_only` (rendered off-screen). Presence → `head :ok` short-circuit.
11. **Legacy/dead code** — don't build on it: `show_hero/minimal/split/card/gallery` + `set_product_for_designs` (products controller), `price_controller.js`, `hello_controller.js`, commented-out product search in products index.
12. **Tests are mostly empty scaffolds.** Only `discounts_controller_test.rb` and `orders_controller_test.rb` are real. `fixtures :all` is commented out and most fixtures are empty templates — write tests with inline records (no factories).
13. **`Game` model is empty** — game scoping is by `game_name` string on products, not an association.
14. **Production hosts**: `accountrift.com`, `*.accountrift.com`, `*.up.railway.app` (see `config/environments/production.rb`).

## Conventions

- **Strong params** use Rails 8 `params.expect(...)` (e.g. `params.expect(order: [:status])`).
- **Style** is `rubocop-rails-omakase` — run `bin/rubocop` before CI.
- **Views** live under `app/views/{products,orders,dashboard/{product,order,feedback,faq,discount},...}`.
- **Dashboard** is a single `DashboardController` with many actions + `_sidebar` partial, not a separate namespace.
- **Flash keys** vary (`:successful_edit`, `:fail_edit`, `:alert`, ...) — follow the existing pattern per feature rather than assuming a standard.
- **Emails** use Resend (production) / `letter_opener` (development). Markdown rendering is Redcarpet + sanitize via `products_helper`.

## Testing

`bin/rails test`. See [`docs/testing.md`](docs/testing.md) for details, what's covered, and how to extend.

## Docs index

- [`docs/README.md`](docs/README.md) — index
- [`docs/setup.md`](docs/setup.md) — local setup + all env vars
- [`docs/architecture.md`](docs/architecture.md) — deep-dive on structure & conventions
- [`docs/database.md`](docs/database.md) — schema + model reference
- [`docs/flows.md`](docs/flows.md) — checkout, webhook, order lifecycle, discounts (with diagrams)
- [`docs/admin-guide.md`](docs/admin-guide.md) — how to run the shop (for humans)
- [`docs/security.md`](docs/security.md) — auth, rate limits, spam protection
- [`docs/deployment.md`](docs/deployment.md) — Kamal, Docker, production
- [`docs/testing.md`](docs/testing.md) — test conventions

When you change code, keep this map accurate — update the relevant line/file entry in the same change.
