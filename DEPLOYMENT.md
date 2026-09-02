# Free demo deployment: Vercel, Render, and Neon

This setup is designed for a protected public demo with no paid infrastructure. It uses Vercel for Flutter Web, Render Free for the API, Neon Free for PostgreSQL, and an HTTPS email provider for password resets and reminders.

## Before deploying

1. Create a Neon project and copy its **pooled** PostgreSQL connection string into `DATABASE_URL`. Keep it secret and do not add it to a repository file.
2. Create an HTTPS email-provider account (the app uses Resend's API) and verify a sender address. Set `RESEND_API_KEY` and `EMAIL_FROM`.
3. Generate three different random values of at least 32 characters for `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, and `REMINDER_CRON_SECRET`.

## Render API

1. Create a Render Blueprint from `render.yaml`. The service is configured as a free Docker web service and does not provision a Render database.
2. Set these Render values: `DATABASE_URL` (Neon pooled URL), `WEB_ORIGINS` (the exact Vercel HTTPS URL), `RESEND_API_KEY`, `EMAIL_FROM`, and `REMINDER_CRON_SECRET`. Leave `REMINDER_SCHEDULER_ENABLED=false`.
3. The container applies Prisma migrations when it starts. Migrations must remain backward-compatible because the free service can restart.

## Vercel web app

1. Import the repository into Vercel and set the **Root Directory** to `client`.
2. Add `API_BASE_URL` with the public HTTPS Render API URL, then deploy.
3. Update Render's `WEB_ORIGINS` if Vercel gives the project a different production URL, then redeploy Render.

The API uses a secure HTTP-only refresh cookie. The most reliable setup is same-site subdomains such as `app.example.com` and `api.example.com`. Without a custom domain, configure a Vercel dashboard rewrite from `/api/(.*)` to `https://your-api.onrender.com/api/$1` and use the Vercel URL as `API_BASE_URL`; this keeps browser API calls same-origin. Never move refresh tokens to local storage as a workaround.

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
5. Visit `https://your-api.onrender.com/health/live`; it should report `ok`.

Do not publish any secret in Vercel variables, Render variables, screenshots, PR descriptions, or commits.
