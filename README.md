# DeuNest

> Never miss what’s due.

A privacy-first web application for tracking document, license, and subscription expiry dates and receiving reminders before they expire or renew.

The first client is planned with Flutter Web and will share the same API with future Flutter mobile applications.

## Project status

This repository contains the product specification, implementation plan, and the deployable foundation. The API has strict environment validation, PostgreSQL migrations, health endpoints, container configuration, and CI checks. The Flutter Web client has an initial application shell and a production build container.

Deployment notes: [DEPLOYMENT.md](DEPLOYMENT.md)
## Phase 1 — MVP

Users can:

- Create an account and sign in
- Track national IDs, driving licenses, and subscriptions
- View expiry status on a dashboard
- Add, edit, archive, and delete tracked items
- Configure reminder schedules
- Receive email reminders
- Optionally connect Google Calendar
- Stay signed in through silent token refresh
- Use up to two active device or browser sessions

Subscription records require provider name, renewal amount, currency, and billing cycle.

## Phase 2 — Growth

Family support is planned for a later phase. Users will be able to add family members and assign tracked items to them.

Additional phases will be defined after the MVP is validated.

## Expiry statuses

| Status | Time remaining |
|---|---:|
| Expired | 0 days or less |
| Critical | 1–7 days |
| Expiring soon | 8–30 days |
| Upcoming | 31–90 days |
| Valid | More than 90 days |

Default reminders are planned for 90, 30, 7, and 1 day before expiry, plus the expiry date.

## Architecture

```text
Flutter Web / Future Flutter Mobile
              |
              | HTTPS JSON API
              v
       Node.js + TypeScript API
              |
       PostgreSQL + Prisma
              |
       Background notification worker
          /                    \\
 Transactional email       Google Calendar
```

The first backend will be a modular monolith. Database access will be isolated behind repository interfaces so the storage layer can evolve as the product grows.

## Planned technology

### Client

- Flutter and Dart
- Riverpod
- GoRouter
- Dio
- Freezed and JSON serialization
- Responsive desktop and mobile web layouts

### Backend

- Node.js and TypeScript
- Express or Fastify, to be selected during foundation work
- PostgreSQL and Prisma
- Background worker for reminders and notification delivery

### Integrations

- Transactional email provider
- Google Calendar API

## Authentication and sessions

- Short-lived access tokens
- Silent refresh without interrupting the user
- Refresh-token rotation and replay detection
- Maximum of two active sessions per user
- A third login revokes the oldest active session
- Explicit logout revokes the current session

The exact token expiry and inactivity policy will be finalized during authentication implementation. Secrets and tokens must remain outside source control.

## Privacy

The MVP follows data minimization principles.

The application stores expiry-related metadata such as item type, title, date, reminder preferences, and optional subscription details. It does not require government ID numbers, passport numbers, driving license numbers, document scans, or photos.

## UI direction

The interface will use an original Apple-inspired glassmorphism design language:

- Translucent surfaces
- Subtle blur and borders
- Large rounded corners
- Calm typography
- Clear status colors
- Light and dark themes
- Accessible contrast and solid-background fallback
- Reduced-motion support

## Disclaimer

This application is an independent reminder tool and is not affiliated with or endorsed by any government authority.
