Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

# Bound the blocking Stripe API calls so a hung upstream can't stall the web
# threads (only 5 in production). Defaults are 30s open / 80s read.
Stripe.open_timeout = 10
Stripe.read_timeout = 30