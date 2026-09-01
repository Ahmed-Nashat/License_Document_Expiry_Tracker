# Deployment guide

This repository is structured to deploy the API, PostgreSQL database, and Flutter Web client as separate services. The current application is the deployable foundation; authentication, document APIs, reminders, and integrations will be added in the next stages before a public production launch.

## Required production services

- Managed PostgreSQL 16 or later, with automated backups and TLS enabled.
- A container runtime or managed container host for `server/Dockerfile`.
- Static hosting or a container host for `client/Dockerfile`.
- A secrets manager for all environment variables.
- A transactional email provider and a worker service once reminders are implemented.

## Environment setup

1. Copy `.env.example` to `.env`; never commit it.
2. Use distinct, random `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` values of at least 32 characters.
3. Set `NODE_ENV=production`, `COOKIE_SECURE=true`, a real `COOKIE_DOMAIN`, and only the permitted HTTPS address in `WEB_ORIGINS`.
4. Configure the managed PostgreSQL URL in `DATABASE_URL`.
5. Apply migrations as part of the release using `npm run prisma:migrate` or the API container startup command.

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
- Before public release, complete and validate authentication, authorization, reminder delivery, account deletion, and a privacy policy.
