# Architecture

How the app is structured and *why* it's shaped this way. Start with the map in [`../AGENTS.md`](../AGENTS.md); this page goes deeper.

## Layers

```
Routes (config/routes.rb)
  └─ Controllers (app/controllers) ── Models (app/models) ── PostgreSQL
        │   │                              └─ Ahoy (visits/events) + Geocoder
        │   └─ Helpers (app/helpers) ── Views (app/views) ── Stimulus (app/javascript)
        └─ Mailers (app/mailers) ── Resend
        └─ Stripe (Checkout API + webhooks)
```

- **Rails 8** with **importmap** (no bundler/webpack). JS is small Stimulus controllers, one per concern.
- **Solid Queue / Cache / Cable** all backed by **Postgres** in production — no Redis anywhere.
- **No background job classes exist.** Time-sensitive side effects (emails, discount redemption) run synchronously inside the Stripe webhook. See [Flows](flows.md).
- **No API mode, no JSON except** `DiscountsController#check_discount` and the Stripe webhook. Views are server-rendered ERB + Turbo.

## The "game" concept

The store is organized around **games**. A game is just a row in `games` (`name`, `official_name`) — but products are NOT associated to games via an FK. Instead, `products.game_name` is a **string** matching the game's `name`. URLs use that string:

```
GET /:game/products      → ProductsController#index   (e.g. /dokkan/products)
GET /:game/products/:id  → ProductsController#show    (e.g. /dokkan/products/5)
GET /games               → GamesController#index
root                     → redirect("/dokkan/products")
```

`ProductsController#index` finds `Game.find_by!(name: params[:game])` (404 if unknown) then queries `Product.visible.where(game_name: params[:game])`. Because of this string-based coupling, renaming a game requires updating `products.game_name` values too.

## Storefront vs Admin

The app has two very different "faces" served by one Rails app:

| | Storefront | Admin |
|---|---|---|
| Auth | None (userless) | Devise sign-in + `admin` boolean |
| Gate | — | `ApplicationController#authenticate_admin!` |
| Entry | `/dokkan/products` | `/dashboard` |
| Controller | Products, Games, Instructions, FAQs, Feedback, SupportMessages, Orders, Discounts (public bits) | `DashboardController` (one controller, many actions) + admin-only actions on the resource controllers |

**Admin is not a namespace.** `DashboardController` hosts `products_index`, `orders_index`, `order_show`, `feedback_index/show`, `faq_index`, `visitors`, `discount_index` and renders partials under `app/views/dashboard/{product,order,feedback,faq,discount}/`. Resource CRUD for products/discounts/faqs/feedbacks/support_messages is spread across their normal controllers with `before_action :authenticate_admin!` on the admin-only actions.

## Conventions worth knowing

- **Strong params** use `params.expect(...)` (Rails 8 style), e.g. `params.expect(order: [:status])`, and nested attributes via `_attributes` keys with `:id` + `:_destroy` for nested rows.
- **Money**: integer cents everywhere in the DB. Helper `convert_from_cents` for display.
- **Flash keys are inconsistent across features** (`:successful_edit`, `:fail_edit`, `:alert`, ...). Follow each feature's existing pattern.
- **Markdown**: user-facing descriptions are rendered by `ProductsHelper.markdown` → Redcarpet (autolink, tables, `filter_html`) then `sanitize`.
- **Pagination**: `pagy` (`pagy(:offset, ...)`), included app-wide in `ApplicationController`.
- **Analytics**: Ahoy with DB store; JS tracking disabled (`Ahoy.api = false`), geocode disabled (`Ahoy.geocode = false`) — IP geocoding happens manually in `Ahoy::Visit` after create using the local MaxMind DB (`vendor/GeoLite2-Country.mmdb`).
- **Rate limiting** is at the Rack layer (`Rack::Attack`), see [Security](security.md).

## Frontend

- `app/javascript/controllers/index.js` eager-loads every `*_controller.js` (Stimulus).
- Notable wiring: `data-controller="checkout-form"` (buy button → loading overlay), `data-controller="discount"` (discount code AJAX + price re-render), `data-controller="product-view"` (carousel/lightbox + variant picker), `data-controller="language-switcher"` (localized descriptions), `data-controller="insert-variant"/"insert-image"` (admin form rows).
- **Legacy/unused**: `price_controller.js` (cart totals — no cart UI), `hello_controller.js` (scaffold), commented-out cart/wishlist targets in `product_view_controller.js`.

## Deployment shape

See [Deployment](deployment.md) for the full picture. One-liner: Docker image (multi-stage, `RUBY_VERSION=3.3.6`) → deployed with **Kamal** → Puma serves the app, `SOLID_QUEUE_IN_PUMA` runs the queue supervisor in-process → assets served from `/rails/public/assets` → Active Storage on Cloudflare R2 → email via Resend.
