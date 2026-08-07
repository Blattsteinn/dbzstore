# dbzstore — Documentation

This folder is the deep-dive reference for the **dbzstore ("Account Rift")** Rails app.
Start with [`../AGENTS.md`](../AGENTS.md) — it's the orientation map. These pages hold the detail.

## Contents

| Page | What it covers |
|---|---|
| [Setup](setup.md) | Local dev environment, prerequisites, all environment variables |
| [Architecture](architecture.md) | Structure, conventions, code layout rationale |
| [Database](database.md) | Schema, models, associations, data rules |
| [Flows](flows.md) | Checkout, Stripe webhook, order lifecycle, discounts — with diagrams |
| [Admin guide](admin-guide.md) | How to run the shop day-to-day (for humans) |
| [Security](security.md) | Auth model, rate limiting, spam protection |
| [Deployment](deployment.md) | Kamal, Docker, production configuration |
| [Testing](testing.md) | How to run and write tests |

## One-line summary

Userless storefront (`/:game/products`) → instant Stripe Checkout (qty always 1) →
Stripe webhook marks order `paid`, decrements stock, emails customer + owner synchronously →
owner fulfills from the admin dashboard (`/dashboard`) and flips status to `processing` / `delivered`.

## Maintenance rule

If you change code, update the corresponding doc (and the file map in `AGENTS.md`) in the **same change** so these never drift.
