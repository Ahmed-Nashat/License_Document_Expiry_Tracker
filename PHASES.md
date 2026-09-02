# DueNest Product Phases

This document summarizes the planned product roadmap and implementation order for DueNest, the privacy-first document, licence, and subscription expiry tracker.

## Product roadmap

### Phase 1 — MVP

The first release supports:

- User registration, login, persistent sessions, and logout
- National ID, driving licence, and subscription tracking
- Create, view, edit, archive, and delete actions
- Expiry status calculation and dashboard visibility
- Subscription provider, renewal amount, currency, and billing cycle
- Custom and default reminder schedules
- Email reminders
- Optional Google Calendar connection
- Responsive web interface

The MVP is complete when a user can register, add an item, see its expiry status, configure reminders, stay signed in through token refresh, and receive the configured notification.

### Phase 2 — Growth

Add family support while preserving ownership for every record:

- Create family members
- Assign documents and subscriptions to family members
- Filter the dashboard by family member
- Prepare owner, editor, and viewer roles

Family UI and permissions should remain out of the MVP.

### Future phases — to be decided

Potential capabilities include:

- Additional document types
- Shared household access and dashboards
- Push, SMS, or WhatsApp notifications
- Subscription history
- Multiple calendar providers
- Import and export
- Paid plans
- Administration and support tools

These ideas should not expand the MVP unless they require a small, low-cost foundation decision.

## Implementation phases

### Step 1 — Foundation

Set up the Flutter client, TypeScript API, PostgreSQL/Prisma, environment loading, formatting, testing, health checks, and CI.

Exit criteria: client and server run independently, migrations succeed, health checks respond, and no secrets are committed.

### Step 2 — Authentication and sessions

Implement registration, login, password hashing, access and refresh tokens, silent refresh, rotation, session revocation, session limits, logout, and the Flutter auth guard.

Exit criteria: refresh keeps users signed in, the oldest session is revoked after the session limit, revoked sessions are rejected, concurrent refresh works, and success/failure paths are tested.

### Step 3 — Document and subscription management

Implement the data models, migrations, CRUD operations, ownership checks, type validation, subscription fields, expiry calculations, pagination, and filtering.

Exit criteria: users cannot access another user’s records, invalid subscription data is rejected, expiry boundaries are tested, and CRUD paths have API tests.

### Step 4 — Dashboard and glass UI

Implement the theme and design tokens, responsive shell, authentication screens, dashboard cards, status groups, add/edit forms, detail views, loading states, empty states, errors, success states, accessibility, and reduced-motion behavior.

Exit criteria: desktop and mobile layouts are usable, every primary action works, server and validation errors are clear, and the main navigation and creation flow are tested.

### Step 5 — Reminder engine and email

Implement reminder rules, scheduled jobs, retries, idempotency, email templates, delivery logging, and notification preferences.

Exit criteria: reminders are delivered at most once per occurrence, failed deliveries retry safely, time zones are tested, and email configuration is documented.

### Step 6 — Google Calendar

Implement OAuth, encrypted token storage, calendar event creation/update/deletion, disconnect behavior, and expired-token handling.

Exit criteria: calendar integration remains optional, users can connect and disconnect safely, event IDs are persisted, and item removal follows an explicit event policy.

### Step 7 — Release hardening

Complete security and dependency reviews, rate limiting, structured safe logs, monitoring, backups, deployment configuration, production validation, browser QA, and privacy/disclaimer work.

Exit criteria: production builds succeed, migrations are repeatable, secrets are externalized, critical flows have evidence-based verification, and the privacy policy and disclaimer are ready.

## Recommended build order

1. Foundation
2. Authentication and session enforcement
3. One complete document type
4. All MVP item types
5. Dashboard and visual system
6. Reminder worker and email
7. Calendar integration
8. Release hardening
