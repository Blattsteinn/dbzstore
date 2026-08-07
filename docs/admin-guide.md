# Admin guide

How to run the shop day-to-day. Written for a human (the owner or a trusted friend), not for code changes.

> You need a user account with the `admin` flag set to `true`. There's no UI to grant admin — it's a DB flag on `users`.

## Logging in

1. Visit the site root (redirects to the storefront, e.g. `/dokkan/products`).
2. Go to `/dashboard` — you'll be asked to sign in (Devise).
3. Sign in with your account email + password.

If you're not an admin you'll be bounced back to the storefront with *"You must be an admin"*.

## Dashboard overview

`/dashboard` shows:
- **Revenue** — sum of paid order items (cached for 1 hour; refresh takes up to an hour)
- **Order counts** — total, paid, pending
- **Recent orders** — last 8
- **Store stats** — product views (today), unique visitors (week), from Ahoy

## Managing products

**Dashboard → Products** (`/dashboard/productss` — yes, three s's, that's the real URL).

- **Create** — via the product form (title, description, game, visibility, priority, deliverables, payment type, images, variants, localized descriptions). Add multiple variants/rows with the *Add variant / Add image* buttons.
- **Visibility** — toggle `live`/`hidden` directly from the list. Hidden products don't appear on the storefront but keep their URL.
- **Duplicate** — makes a copy including all variants (title gets `" Copy"` appended) so you can clone a product and tweak it.
- **Delete** — removes the product; **past orders are preserved** (order items keep a price snapshot).

**Variants** carry the real sellable info: `title`, `price` (in cents — display auto-converts), `stock`. Stock is what decrements on each paid order.

## Managing orders

**Dashboard → Orders** (`/dashboard/orders`) — filterable by status.

- Open an order to see customer email/Discord, items, discount applied, and Stripe session.
- **Advance the status**: `paid → processing → delivered`. Use `refunded` if you refund via Stripe, `cancelled` if you void it manually.
- When an order is marked `paid` (by the Stripe webhook), the customer gets an email, you get a notification email, variant stock is decremented, and any discount code is redeemed automatically. You only handle fulfillment after that.

## Discounts

**Dashboard → Discounts** (`/dashboard/discount_index`).

- Create a code with a **percentage** and an **amount** (how many uses to issue). `remaining` starts equal to `amount`.
- Customers type the code on the product page — it shows the % off before they pay.
- A use is consumed **only when a payment completes** (not when the code is merely previewed/entered).
- Codes are checked against `remaining`; exhausted codes show as invalid.

## FAQs

**Dashboard → FAQs** (`/dashboard/faq_index`). Add/edit/remove question-answer pairs; shown publicly on the FAQ page.

## Feedback

**Dashboard → Feedback** (`/dashboard/feedback_index`). Public visitors can leave one rating (1–5) + comment per order using the order's code (the 20-char `public_id` they received). Review these, and edit/delete as needed (e.g. spam).

## Support messages

**Dashboard → visitors/support** — support messages submitted via the contact form are keyed to an order. Open them, reply (status update), and close them out. There's an open-messages counter in the sidebar.

## Visitors

**Dashboard → Visitors** (`/dashboard/visitors`) — paginated Ahoy visit log with geolocation (country/city) from the MaxMind DB. Useful for spotting bot traffic or where customers come from.

## Things that look like bugs but are intentional

- The products dashboard URL really is `/dashboard/productss` (typo in routes). Don't be surprised.
- Emails to you arrive under subject *"Order received, {price} EUR"*; customer emails under *"Order {public_id} delivery"*.
- There's no cart and no wishlist UI, even though the README mentions them.
