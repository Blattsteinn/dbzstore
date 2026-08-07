# Setup

How to get this app running locally, and every environment variable it needs.

## Prerequisites

- Ruby **3.3.6** (`./ruby-version`)
- PostgreSQL (development DBs: `account_rift_development`, `account_rift_test`)
- Bundler (`gem install bundler`)
- libvips (for Active Storage image variants) — required in production build too

## Quick start

```bash
bin/setup                # bundle install + db:prepare (+ optional --reset)
bin/dev                  # start the server on http://localhost:3000
```

`bin/setup` details: runs `bundle check || bundle install`, then `bin/rails db:prepare`, clears logs/tmp, and starts the server unless `--skip-server` is passed. `db:prepare` creates the databases and runs migrations/seeds.

> Note: there is no `Procfile.dev` — `bin/dev` just runs `rails server`.

## Environment variables

`dotenv-rails` is loaded in **development and test**, so you can put these in a local `.env` file (not committed). There is a checked-in template at [`../.env.example`](../.env.example). Production values come from the deploy secret store / platform env.

| Variable | Required | Used by | Notes |
|---|---|---|---|
| `STRIPE_SECRET_KEY` | ✅ (any env using payments) | `config/initializers/stripe.rb` | Stripe API key (test mode for local dev) |
| `STRIPE_WEBHOOK_SECRET` | ✅ for webhooks | `app/controllers/stripe_webhooks_controller.rb` | From `stripe listen`/dashboard; verifies `checkout.session.*` events |
| `RESEND_API_KEY` | ✅ to send email | `config/initializers/resend.rb` | Transactional email provider |
| `CLOUDFLARE_ACCOUNT_ID` | prod only | `config/storage.yml` | R2 endpoint id |
| `CLOUDFLARE_ACCESS_KEY_ID` | prod only | `config/storage.yml` | R2 access key |
| `CLOUDFLARE_SECRET_ACCESS_KEY` | prod only | `config/storage.yml` | R2 secret |
| `CLOUDFLARE_BUCKET` | prod only | `config/storage.yml` | R2 bucket name |
| `DATABASE_URL` | prod only | `config/database.yml` | All 4 connections (primary/cache/queue/cable) in production |
| `RAILS_MASTER_KEY` | prod only | Kamal / `config/master.key` | Encrypted credentials |
| `RAILS_MAX_THREADS` | optional | `config/database.yml`, `config/puma.rb` | Default 5 |
| `PORT` | optional | `config/puma.rb` | Default 3000 |
| `WEB_CONCURRENCY` | optional | Puma workers | Set on the server |
| `SOLID_QUEUE_IN_PUMA` | optional | `config/puma.rb` | If set, runs Solid Queue supervisor inside Puma |
| `JOB_CONCURRENCY` | optional | `config/queue.yml` | Queue worker processes |
| `RAILS_LOG_LEVEL` | optional | production env | e.g. `info` |
| `CI` | optional | `config/environments/test.rb` | If set, eager-loads in test |

### Local dev email

In development the mailer is `letter_opener` — emails open in a browser tab instead of being sent. Set up Stripe test keys + a `.env` and you can run the full checkout flow locally (use Stripe's test card `4242 4242 4242 4242`).

### Webhooks locally

To test `checkout.session.completed`, run Stripe's CLI and point it at your app:

```bash
stripe listen --forward-to localhost:3000/stripe/webhooks
# copy the webhook signing secret into STRIPE_WEBHOOK_SECRET
```

## Seeds

```bash
bin/rails db:seed
```

The seeds populate games (e.g. `dokkan`, `legends`) and demo products/variants. See `db/seeds.rb`.

## Common issues

- **Missing `.env`** → Stripe calls fail with `Stripe::AuthenticationError`. Copy `.env.example` → `.env` and fill in.
- **Active Storage variants fail** → libvips not installed.
- **`db:prepare` on empty DB** → `bin/rails db:prepare` handles creation + schema load; add `--reset` via `bin/setup --reset` if needed.
