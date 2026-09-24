# Deploy and Host Invoice Ninja on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/invoice-ninja-5?utm_medium=integration&utm_source=button&utm_campaign=invoice-ninja-5)

[Invoice Ninja](https://invoiceninja.com/) is self-hosted invoicing and billing for freelancers and small businesses: invoices, quotes, recurring invoices and subscriptions, expenses, time tracking, and a client portal where clients view and pay invoices through Stripe, PayPal, GoCardless and more than a dozen other payment gateways. Its source is on GitHub under the Elastic License 2.0. This template runs the official Invoice Ninja 5 image with everything it needs working from the first boot: PDF generation, the queue worker, the scheduler, and nightly backups.

## About Hosting Invoice Ninja

The stack is three pieces: Invoice Ninja (nginx, PHP-FPM, queue worker and scheduler in one service), a private MariaDB, and a Railway bucket for backups.

- **No open setup page.** A fresh Invoice Ninja shows its setup screen to whoever opens the URL first. This template creates your admin account on the first boot, before the site answers, with your email and a generated password. The database has a generated password and no public proxy.
- **PDFs, emails and recurring invoices work.** The official image renders PDFs with Chrome, which is included and set up here. The queue worker sends emails and builds PDFs in the background, and the scheduler runs recurring invoices, reminders and auto-billing every hour. Queued jobs are stored in MariaDB, so they survive restarts.
- **Pinned and upgraded on purpose.** The template pins Invoice Ninja 5.13.43 instead of `latest`, so a new upstream release never lands in the middle of your month. Database migrations run on every boot, so updating means bumping the tag and redeploying.
- **Nightly backups.** Every night at 03:00 UTC the database, uploaded files and the encryption key go to the bundled bucket, one archive per weekday, so the last 7 days are always there. Restoring is one command.

## Common Use Cases

- Invoicing and quotes for freelancers, agencies and small businesses, in 144 currencies and 45 languages
- Recurring invoices and subscriptions, with automatic card or bank charges through a payment gateway
- A branded client portal where clients see their invoices, quotes and payments and pay online

## Dependencies for Invoice Ninja Hosting

- MariaDB 11.8 LTS (included, private network only)
- A Railway bucket for backups (included)

### Deployment Dependencies

- [Invoice Ninja user guide](https://invoiceninja.github.io/en/user-guide/)
- [Self-hosting docs](https://invoiceninja.github.io/en/self-host-installation/)
- [Template source on GitHub](https://github.com/nomideusz/invoiceninja-railway)

### Implementation Details

**Sign in** at your service's domain with the email you entered at deploy (`IN_USER_EMAIL`) and the `IN_PASSWORD` value from the Invoice Ninja service's Variables tab. Change the password under Settings → User Details. Both variables are read on the first boot only.

**Email.** Invoice Ninja emails invoices, quotes and reminders to your clients. Railway allows outbound SMTP only on the Pro plan, so on any plan the easiest route is an email provider's API: in Settings → Email Settings, set the sending method to Postmark, Mailgun, Brevo or Amazon SES and paste the API key. On Pro you can use SMTP for everything instead: set `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_ENCRYPTION=tls`, `MAIL_FROM_ADDRESS` and `MAIL_FROM_NAME` on the Invoice Ninja service. Until then, the system mailer is set to `log`: system emails are written to the service's logs instead of being sent. That includes password resets, so a lost password can be recovered by requesting a reset and copying the link from the logs.

**Backups and restore.** Backups appear in the Backups bucket as `invoiceninja-Mon.tar.gz` … `invoiceninja-Sun.tar.gz`, each holding the database, the uploaded files (logos, documents) and the `APP_KEY`. For an extra backup before a risky change, run `invoiceninja-backup` in a `railway ssh` session on the Invoice Ninja service. It replaces today's file. To roll back, run `invoiceninja-restore Mon` (or any other weekday) there. It replaces the database and files with that backup's. Payment gateway, email and bank credentials are stored encrypted with `APP_KEY`: restoring into a new deployment prints the old key, and you set it as the new service's `APP_KEY`.

**Memory.** Measured on Railway: about 400 MB for Invoice Ninja at rest and 0.7 GB after Chrome has rendered a burst of PDFs, plus about 170 MB for MariaDB. On plans with less than 2 GB per service, one queue worker runs instead of two, which saves about 100 MB, so the Trial plan's 1 GB is enough. The Free plan's 0.5 GB per service is not enough to render PDFs.

**Custom domain.** Add it in the Invoice Ninja service's Settings → Networking, then set `APP_URL` to `https://<your domain>` and redeploy. Links in emails and PDFs use `APP_URL`.

**Updates.** Change the image tag in the [template's Dockerfile](https://github.com/nomideusz/invoiceninja-railway/blob/main/Dockerfile) (fork it and point the service at your fork) and redeploy. Take a backup first. Migrations run on the next boot. Invoice Ninja's built-in updater is off in Docker installs.

**Changes from the upstream image, all in the wrapper:**

- nginx runs inside the service, since a Railway volume attaches to one service and the official setup shares volumes with a separate nginx container.
- The visitor's IP comes from Railway's `X-Real-IP` header, so login throttling and client portal activity see real addresses. Forwarded headers sent by clients are ignored.
- PHP-FPM listens on localhost only. OPcache is off for the CLI workers, which saves about 200 MB.
- Logs go to Railway's log view instead of a file on the volume that would grow forever.

## Why Deploy Invoice Ninja on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Invoice Ninja on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
