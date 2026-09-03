# Vercel deployment with Neon

The primary deployment uses one Vercel project for Flutter Web, a second Vercel project for the Fastify API, and Neon for PostgreSQL. Render remains documented below as an optional API alternative.

## Before deploying

1. Create a Neon project and copy its **pooled** PostgreSQL connection string into `DATABASE_URL`. Keep it secret and do not add it to a repository file.
2. Reuse the Google Cloud project and OAuth client already represented by `GMAIL_CLIENT_ID` and `GMAIL_CLIENT_SECRET`. Enable the Google Calendar API and authorize the existing client for both Gmail sending and Calendar event access as described below. Do not create a second OAuth client.
3. Generate three different random values of at least 32 characters for `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, and `REMINDER_CRON_SECRET`.

## API deployment (Vercel, no card required)

1. Create a second Vercel project from the same repository and set **Root Directory** to `server`.
2. Use the included `server/vercel.json`. Its build command runs `prisma generate` only; it does not run database migrations.
3. Add the same API variables listed below to this Vercel project. Set `HOST=0.0.0.0`, `NODE_ENV=production`, and leave `REMINDER_SCHEDULER_ENABLED=false`.
4. Deploy and copy the resulting API URL. Test `/health/live`.

Database migrations must be reviewed and run separately from Vercel builds. This Calendar release does not add a migration.

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
5. Use **Add to Google Calendar** on that document and verify the event appears on the exact selected expiry date.
6. Visit `https://your-api.onrender.com/health/live`; it should report `ok`.

Do not publish any secret in Vercel variables, Render variables, screenshots, PR descriptions, or commits.

## Google Calendar authorization

This integration writes to the authorized application owner's primary Google Calendar. It does not connect each DueNest user to a personal Google account.

1. Open the same Google Cloud project used by the existing Gmail OAuth client.
2. In **APIs & Services → Library**, enable **Google Calendar API**. Keep the Gmail API enabled.
3. In **Google Auth Platform → Data Access**, ensure the consent configuration includes both scopes:
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/calendar.events`
4. In **Google Auth Platform → Audience**, if the app is External and still in Testing, keep the application owner's Google account in the test-user list.
   - For a long-lived Vercel deployment, do not leave an External OAuth app in Testing: Google limits these refresh tokens to seven days when Gmail or Calendar scopes are requested. Move the app to Production and complete any verification Google requires, or use an Internal app when the account belongs to the same Google Workspace organization.
5. Reuse the existing OAuth client. If it is a Web application client, add `http://127.0.0.1:53682/oauth2callback` to that client's authorized redirect URIs. Desktop clients do not require that console entry.
6. From PowerShell, change to the `server` directory and run the one-time authorization command:

   ```powershell
   npm.cmd run google:authorize -- "<path-to-the-existing-oauth-client-json>"
   ```

7. This command does not host DueNest locally. It starts a temporary loopback callback only while Google completes authorization, then closes it. In the browser, select the application owner's account and approve both Gmail sending and Calendar event access. The script writes the replacement refresh token to the ignored `server/.gmail-token.json` file. Never commit, log, upload, or paste that file into chat.
8. Copy the new refresh token into `GMAIL_REFRESH_TOKEN` in each backend environment. Keep `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, and `EMAIL_FROM` unchanged.
9. Before production rollout, verify both a password-reset email and **Add to Google Calendar** with the new token.

## Vercel Calendar release

1. Complete the Google authorization steps locally and retain the previous deployed refresh token only in a secure rollback location or the hosting provider's environment-variable history.
2. Deploy the backend Vercel project from the `server` root. Do not add a migration command to `server/vercel.json` or the Vercel build settings.
3. In the backend project's encrypted environment variables, replace only `GMAIL_REFRESH_TOKEN` with the newly authorized value. The required Google variables remain `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`, and `EMAIL_FROM`.
4. Redeploy the backend and verify `/health/live`, password reset, reminder delivery, and Calendar creation.
5. Deploy the Flutter project from the `client` root. No Google credential belongs in the Flutter or Vercel frontend environment.
6. Confirm desktop and mobile-width layouts show **Add to Google Calendar** and that success appears only after the event exists in Google Calendar.

## Calendar rollback

1. Redeploy the previous application commit for both the backend and Flutter client.
2. Restore the previous `GMAIL_REFRESH_TOKEN` from the secure hosting-provider history only if the new token prevents Gmail delivery. Do not change the OAuth client ID, client secret, or sender address.
3. Re-test password reset and reminder delivery immediately after rollback.
4. The Calendar change has no Prisma migration, so no database rollback is needed.
