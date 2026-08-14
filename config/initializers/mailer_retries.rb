# Mailers are delivered async (deliver_later → ActionMailer::MailDeliveryJob).
# `retry_on` isn't available on mailer classes directly, so configure it on the
# delivery job: transient failures (e.g. a Resend API hiccup) are retried with
# exponential backoff instead of being lost forever.
ActionMailer::MailDeliveryJob.retry_on StandardError, wait: :exponentially_longer, attempts: 5
