# Vercel deployment with Neon

The primary deployment uses one Vercel project for Flutter Web, a second Vercel project for the Fastify API, and Neon for PostgreSQL. Render remains documented below as an optional API alternative.

## Before deploying

1. Create a Neon project and copy its **pooled** PostgreSQL connection string into `DATABASE_URL`. Keep it secret and do not add it to a repository file.
2. Keep the existing Gmail OAuth client represented by `GMAIL_CLIENT_ID` and `GMAIL_CLIENT_SECRET`. Enable the Google Calendar API and create a **Web application** OAuth client in the same Google Cloud project for per-user Calendar connections. These are separate clients for separate purposes; the Gmail client is not replaced.
3. Generate three different random values of at least 32 characters for `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, and `REMINDER_CRON_SECRET`.

## API deployment (Vercel, no card required)

1. Create a second Vercel project from the same repository and set **Root Directory** to `server`.
2. Use the included `server/vercel.json`. Its build command runs `prisma generate` only; it does not run database migrations.
3. Add the same API variables listed below to this Vercel project. Set `HOST=0.0.0.0`, `NODE_ENV=production`, and leave `REMINDER_SCHEDULER_ENABLED=false`.
4. Deploy and copy the resulting API URL. Test `/health/live`.

Database migrations must be reviewed and run separately from Vercel builds. This Calendar release adds a migration for encrypted per-user Calendar connections; apply it manually before deploying the API.

## Render API (alternative)

1. Create a Render Blueprint from `render.yaml`. The service is configured as a free Docker web service and does not provision a Render database. Render may require account payment verification even for free services.
2. Set these Render values: `DATABASE_URL` (Neon pooled URL), `WEB_ORIGINS` (the exact Vercel HTTPS URL), `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`, `EMAIL_FROM` (for example `DueNest <due.nest11@gmail.com>`), and `REMINDER_CRON_SECRET`. Leave `REMINDER_SCHEDULER_ENABLED=false`.
3. The container applies Prisma migrations when it starts. Migrations must remain backward-compatible because the free service can restart.

## Vercel web app

1. Import the repository into Vercel and set the **Root Directory** to `client`.
2. Add `RENDER_API_URL` with the public HTTPS URL of the separate Vercel API project, then deploy. The name is retained for backward compatibility; it can point to Vercel and does not require Render.
3. Add the Flutter Vercel project's exact HTTPS URL to the API project's `WEB_ORIGINS`, then redeploy the API.

The Vercel API proxy keeps browser API calls and the HTTP-only refresh cookie first-party, even when Render uses its free `onrender.com` URL. Never move refresh tokens to local storage as a workaround.

## Free-tier reminder trigger

Render Free services can sleep when idle, so the built-in scheduler remains disabled. The repository includes `.github/workflows/reminder-cron.yml`, which calls the protected endpoint hourly. Add these GitHub repository secrets:

- `REMINDER_CRON_URL`: `https://your-api.onrender.com/api/internal/reminders/run`
- `REMINDER_CRON_SECRET`: exactly the same value configured in Render.

The workflow is suitable for a demo; free hosting and scheduled workflows are not a precise, always-on job system. Reminder delivery is best-effort. Use a dedicated scheduler/worker before relying on reminders operationally.

## Final public checks

1. Open the deployed Vercel site and register a test account.
2. Refresh the page, sign out, and sign back in.
3. Complete a password-reset email flow.
4. Create a document and confirm a reminder is queued after manually running the GitHub workflow.
5. Connect a test user's Google Calendar, create an item with **Add to my Google Calendar** selected, and verify the event appears on the exact selected expiry date.
6. Visit `https://your-api.onrender.com/health/live`; it should report `ok`.

Do not publish any secret in Vercel variables, Render variables, screenshots, PR descriptions, or commits.

## Google authorization

Gmail and Calendar now have separate purposes:

- The existing installed-app Gmail client remains responsible for password-reset and reminder email delivery.
- A new **Web application** client in the same Google Cloud project lets each DueNest user connect their own `primary` Google Calendar. Its tokens are encrypted before database storage and never sent to Flutter.

### Keep Gmail working

1. Keep the Gmail API enabled and retain `https://www.googleapis.com/auth/gmail.send` in **Google Auth Platform → Data Access**.
2. From PowerShell, change to the `server` directory and run the one-time authorization command:

   ```powershell
   npm.cmd run google:authorize -- "<path-to-the-existing-oauth-client-json>"
   ```

3. This command does not host DueNest locally. It starts a temporary loopback callback only while Google completes authorization, then closes it. Approve Gmail sending. The script writes the replacement refresh token to the ignored `server/.gmail-token.json` file. Never commit, log, upload, or paste that file into chat.
4. Copy the new refresh token into `GMAIL_REFRESH_TOKEN` in each backend environment. Keep `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, and `EMAIL_FROM` unchanged.

### Set up per-user Calendar connections

1. In the same Google Cloud project, enable **Google Calendar API**.
2. In **Google Auth Platform → Data Access**, add `https://www.googleapis.com/auth/calendar.events`.
3. In **Google Auth Platform → Clients**, create an OAuth client of type **Web application**. Do not alter or delete the Gmail installed-app client.
4. Add this exact authorized redirect URI to the new Web client:

   ```text
   https://YOUR-VERCEL-BACKEND-DOMAIN/api/calendar/oauth/callback
   ```

5. In **Audience**, add test users while the app is in Testing. For production, publish the app and complete any Google verification required for the Calendar scope.
6. Add these API-only Vercel variables from the new Web client:

   ```text
   GOOGLE_CALENDAR_CLIENT_ID
   GOOGLE_CALENDAR_CLIENT_SECRET
   GOOGLE_CALENDAR_REDIRECT_URI
   GOOGLE_TOKEN_ENCRYPTION_KEY
   ```

   `GOOGLE_CALENDAR_REDIRECT_URI` must exactly match the URI in Google Cloud. Generate `GOOGLE_TOKEN_ENCRYPTION_KEY` from 32 random bytes encoded as base64url, save it in a password manager, and do not rotate it without a token re-encryption procedure.

## Vercel Calendar release

1. Create the new Web OAuth client and set its API-only environment variables as described above.
2. Apply the reviewed migration manually from the `server` directory:

   ```powershell
   npm.cmd run prisma:migrate
   ```

   Do not add that command to `server/vercel.json` or Vercel build settings.
3. Deploy the backend Vercel project from the `server` root.
4. Deploy the Flutter project from the `client` root. No Google credential belongs in Flutter or the frontend Vercel environment.
5. Verify `/health/live`, password reset, reminder delivery, user Calendar connection, and Calendar creation on desktop and mobile layouts.

## Calendar rollback

1. Redeploy the previous application commit for both the backend and Flutter client.
2. Keep the migration in place; it only stores optional Calendar connections and is backward-compatible. Disconnecting users or redeploying the previous application version does not affect Gmail.
3. Restore the previous `GMAIL_REFRESH_TOKEN` only if Gmail delivery fails. Do not change the OAuth client ID, client secret, or sender address.
4. Re-test password reset and reminder delivery immediately after rollback.
