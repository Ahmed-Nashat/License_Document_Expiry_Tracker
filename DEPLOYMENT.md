# Deployment guide

This repository deploys the API, PostgreSQL database, and Flutter Web client as separate services. It includes authentication, document tracking, email reminders, and the supporting production safeguards described below.

## Required production services

- Managed PostgreSQL 16 or later, with automated backups and TLS enabled.
- A container runtime or managed container host for `server/Dockerfile`.
- Static hosting or a container host for `client/Dockerfile`.
- A secrets manager for all environment variables.
- A transactional email provider for password-reset and reminder emails.

## Environment setup

1. Copy `.env.example` to `.env`; never commit it.
2. Use distinct, random `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` values of at least 32 characters.
3. Set `NODE_ENV=production`, a real `COOKIE_DOMAIN` where needed, and only the permitted HTTPS address in `WEB_ORIGINS`. Secure cookies and `SameSite=None` are enforced automatically in production so a Vercel web app can use the Render API.
4. Configure the managed PostgreSQL URL in `DATABASE_URL`.
5. Apply migrations as a release step using `npm run prisma:migrate`; the Render Blueprint runs this before each paid-service deployment.
6. Set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, and `SMTP_PASS` for the transactional email provider.
7. Build the web image with the public HTTPS API address: `docker build --build-arg API_BASE_URL=https://api.example.com -t deunest-web client`.

## Vercel and Render release setup

1. In Render, create a Blueprint from `render.yaml`. It provisions the API and PostgreSQL in Frankfurt, runs migrations in Render's pre-deploy phase, and creates the JWT secrets.
2. In the Render API service, set `WEB_ORIGINS` to the exact Vercel production URL (for example, `https://your-app.vercel.app`) and add the SMTP credentials. For the most reliable sign-in experience, use related custom domains such as `app.example.com` on Vercel and `api.example.com` on Render. Do not set `COOKIE_DOMAIN` unless you intentionally need a shared cookie domain.
3. In Vercel, import the repository and set `API_BASE_URL` to the public HTTPS Render API URL. The build fails immediately if it is missing.
4. Redeploy the Render API after setting `WEB_ORIGINS`, then deploy Vercel. Verify sign-in, page refresh, sign-out, password reset, and `/health/ready` using a staging account.

## Local container smoke test

Docker Desktop's command-line executable is installed at `C:\Program Files\Docker\Docker\resources\bin\docker.exe` on this machine. After adding a local `.env` with a strong database password and auth secrets, run:

```powershell
& 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' compose up --build
```

Then check:

```powershell
Invoke-WebRequest http://localhost:3000/health/live
Invoke-WebRequest http://localhost:3000/health/ready
```

## Release safeguards

- Run CI on every pull request; it builds and tests both deployable artifacts.
- Use rolling releases with backward-compatible database migrations.
- Add uptime monitoring against `/health/live` and alert on failures.
- Restrict CORS to the deployed web origins.
- Keep logs free of session cookies, authorization headers, passwords, document numbers, and OAuth tokens.
- Before public release, verify a password reset email and a reminder email using a staging account. The deployment must set `API_BASE_URL`; Vercel builds fail fast when it is absent.
