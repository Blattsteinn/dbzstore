# Deployment

How this app runs in production: Docker image, Kamal deploy, and the production configuration.

## Stack in production

- **Rails 8.1** on Puma (threads from `RAILS_MAX_THREADS`, default 5)
- **PostgreSQL** — one server, **four databases/connections**: `primary`, `cache` (Solid Cache), `queue` (Solid Queue), `cable` (Solid Cable). All from `DATABASE_URL`.
- **Solid Queue** supervisor runs **inside Puma** when `SOLID_QUEUE_IN_PUMA` is set (which Kamal does via `env.clear`). Note: no job classes exist yet; mailers run synchronously.
- **Active Storage** → **Cloudflare R2** (S3-compatible) in production, disk in dev/test.
- **Email** → Resend (production) / letter_opener (dev).
- **Assets** → served from `/rails/public/assets` (compiled in the image); PWA views present but routes commented out.

## The Docker image (`Dockerfile`)

Multi-stage build:
- Base `ruby:3.3.6`, installs **jemalloc**, **libvips**, **postgresql-client**.
- Uses **Bundler 4.0.4**.
- Precompiles assets with `SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile` (needs `RAILS_MASTER_KEY` at runtime, not build).
- Runs as non-root user `rails`.
- `ENTRYPOINT ["bin/docker-entrypoint"]` — runs `bin/rails db:prepare` + loads `cache`/`queue`/`cable` schemas on boot.
- `CMD ["./bin/rails", "server", "-b", "0.0.0.0"]` (Thruster CMD is commented out).

## Kamal (`config/deploy.yml`)

- Service/image name: `account_rift` (`service: account_rift`, `image: account_rift`).
- **Server is a placeholder** (`192.168.0.1`) — update to the real host before first deploy.
- Registry: local `localhost:5555` (update to a real registry for production).
- `env.secret: [RAILS_MASTER_KEY]` — encrypted credentials via the master key.
- `env.clear: SOLID_QUEUE_IN_PUMA: "true"` — queue runs in-process.
- Volume: `account_rift_storage:/rails/storage` (persistent Active Storage).
- `asset_path: /rails/public/assets`, `builder.arch: amd64`.
- Aliases defined: `console`, `shell`, `logs`, `dbc`.

Deploy flow (standard Kamal):

```bash
bin/kamal setup    # first time (provisions server, registry, secrets)
bin/kamal deploy   # build + push image + rollout
bin/kamal console  # rails console on the server
bin/kamal logs     # follow logs
```

## Production environment highlights (`config/environments/production.rb`)

- `default_url_options host: "accountrift.com"` — used for URLs generated in emails (e.g. instructions/cancel links).
- `assume_ssl` + `force_ssl`.
- `config.hosts = ["accountrift.com", /.*\.accountrift\.com/, /.*\.up\.railway\.app/]` — note the Railway host is allowed (legacy of a previous host).
- Active Storage service `:cloudflare` (R2), cache `:solid_cache_store`, queue adapter `:solid_queue` (writes to `queue` DB).
- Mailer `:resend`, `log_level` from `RAILS_LOG_LEVEL` (default `info`).

## Recurring maintenance

`config/recurring.yml` (production only) clears finished Solid Queue jobs hourly at minute 12:

```yaml
production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
```

## Production secrets checklist

- `RAILS_MASTER_KEY` (Kamal secret)
- `DATABASE_URL`
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- `RESEND_API_KEY`
- `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_ACCESS_KEY_ID`, `CLOUDFLARE_SECRET_ACCESS_KEY`, `CLOUDFLARE_BUCKET`
- `RAILS_MAX_THREADS`, `WEB_CONCURRENCY`, `JOB_CONCURRENCY` as needed
- `SOLID_QUEUE_IN_PUMA=true`

## Health check

`GET /up` → `rails/health#show` (Rails 8 built-in). Returns `200` if the app boots, `500` otherwise — used by load balancers/uptime monitors.
