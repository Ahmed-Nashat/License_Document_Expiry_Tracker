# License & Document Expiry Tracker — Implementation Plan

## 1. Product vision

Build a privacy-first expiry assistant where people can record important document, license, and subscription dates and receive reminders before they expire or renew.

The first client will be Flutter Web, with the architecture prepared for future iOS and Android applications. The web and mobile clients will use the same backend API and business rules.

The product stores only the metadata needed for reminders. It does not require government ID numbers, passport numbers, license numbers, document scans, or document photos.

## 2. Current repository state

The repository currently contains only the project specification in `README.md`. There is no application code, package manifest, database schema, test suite, or environment configuration yet.

Implementation will therefore start by creating the project structure and foundation.

## 3. Agreed technology direction

### Client

- Flutter and Dart
- Flutter Web for the first release
- Future Flutter iOS and Android clients
- Riverpod for state management
- GoRouter for navigation and authentication redirects
- Dio for HTTP communication
- Freezed and JSON serialization for immutable API models
- Responsive layout supporting desktop, tablet, and mobile web

### Backend

- Node.js and TypeScript
- Modular monolith API
- Express or Fastify, selected during foundation work
- PostgreSQL for the first implementation
- Prisma ORM
- Background worker for email and calendar-related jobs

MongoDB remains a possible future option, but it is not required for initial scalability. The application layer should isolate database access behind repositories so a future database change does not affect Flutter or domain logic.

### Integrations

- Transactional email provider
- Google Calendar integration
- Optional calendar connection; the application must work without it

## 4. Product phases

### Phase 1 — MVP

Supported item types:

- National ID
- Driving license
- Subscription

Core capabilities:

- User registration and login
- Persistent authenticated session
- Dashboard showing expiry status
- Create, view, edit, archive, and delete tracked items
- Required subscription provider and renewal amount
- Subscription billing cycle
- Custom reminder schedule
- Default reminder schedule
- Email reminders
- Optional Google Calendar connection
- Calendar event creation and removal
- Responsive glassmorphism interface

Subscription fields:

```text
providerName: required
renewalAmount: required
currency: required
billingCycle: monthly | yearly | custom
```

The renewal amount represents the recurring amount for the selected billing cycle. A later phase can add a separate next-renewal amount if variable pricing is needed.

### Phase 2 — Growth

Add family support without changing the Phase 1 document model:

- Create family members
- Assign documents and subscriptions to a family member
- Filter the dashboard by family member
- Preserve an owner for every record
- Add future roles such as owner, editor, and viewer

The database should be designed with ownership and relationships ready for this phase, but family UI and permissions should not be exposed in the MVP.

### Future phases — undecided

Potential future capabilities, not committed yet:

- More document types
- Shared family access
- Push notifications
- SMS or WhatsApp notifications
- Recurring subscription history
- Multiple calendar providers
- Import/export
- Household dashboards
- Paid plans
- Admin and support tools

These should not influence MVP implementation unless they create a clear, low-cost foundation requirement.

## 5. Expiry and reminder rules

Expiry status is calculated from the current date and is not permanently stored as a source of truth.

| Status | Time remaining |
|---|---:|
| Expired | 0 days or less |
| Critical | 1–7 days |
| Expiring soon | 8–30 days |
| Upcoming | 31–90 days |
| Valid | More than 90 days |

Default reminders:

- 90 days before expiry
- 30 days before expiry
- 7 days before expiry
- 1 day before expiry
- On the expiry date

Reminder rules must be configurable per item. The notification worker must be idempotent so retries never send duplicate notifications for the same user, item, reminder rule, and occurrence.

Dates that represent expiry should be stored as date-only values. Timestamps such as creation, updates, delivery attempts, and token activity should be stored in UTC. Reminder delivery should use the user’s selected time zone.

## 6. System architecture

```text
Flutter Web / Future Flutter Mobile
              |
              | HTTPS JSON API
              v
       Node.js TypeScript API
              |
       PostgreSQL + Prisma
              |
       Background job worker
          /             \
 Transactional email   Google Calendar
```

Start as a modular monolith. Keep modules internally separated, but deploy the API and worker simply until scale requires independent services.

Backend modules:

- Auth
- Users
- Documents
- Subscriptions
- Reminder rules
- Notifications
- Calendar integration
- Sessions and device management
- Future family members
- Audit and security events

The server owns authorization, expiry calculations, reminder generation, token validation, and integration credentials. Flutter owns presentation, local form state, navigation, and user interaction.

## 7. Suggested repository structure

```text
license-tracker/
├── client/
│   ├── lib/
│   │   ├── app/
│   │   │   ├── router/
│   │   │   ├── theme/
│   │   │   └── app.dart
│   │   ├── core/
│   │   │   ├── errors/
│   │   │   ├── network/
│   │   │   ├── storage/
│   │   │   └── widgets/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── documents/
│   │   │   ├── reminders/
│   │   │   ├── calendar/
│   │   │   └── settings/
│   │   └── shared/
│   │       ├── models/
│   │       └── utilities/
│   └── test/
├── server/
│   ├── src/
│   │   ├── config/
│   │   ├── middleware/
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── documents/
│   │   │   ├── reminders/
│   │   │   ├── notifications/
│   │   │   ├── calendar/
│   │   │   └── sessions/
│   │   ├── jobs/
│   │   └── shared/
│   ├── prisma/
│   │   └── schema.prisma
│   └── test/
├── plans/
│   └── implementation-plan.md
├── .env.example
├── .gitignore
└── README.md
```

Each Flutter feature should separate `data`, `domain`, and `presentation` concerns. Each backend module should separate routes/controllers, validation, service/use-case logic, and repositories.

## 8. Phase 1 data model

Core entities:

```text
User
UserSession
Document
ReminderRule
NotificationDelivery
CalendarConnection
CalendarEvent
```

### User

```text
id
email
passwordHash
displayName optional
timeZone
emailNotificationsEnabled
createdAt
updatedAt
```

### UserSession

```text
id
userId
deviceName
deviceType
refreshTokenHash
createdAt
lastUsedAt
lastRefreshAt
revokedAt optional
expiresAt optional
```

The session represents a browser profile or mobile app installation, not a guaranteed physical device.

### Document

```text
id
userId
type: national_id | driving_license | subscription
title
expiryDate
notes optional
providerName optional
renewalAmount optional
currency optional
billingCycle optional
isArchived
createdAt
updatedAt
```

Server validation must require `providerName`, `renewalAmount`, `currency`, and `billingCycle` for subscription records. They are not required for IDs or driving licenses.

### ReminderRule

```text
id
documentId
daysBeforeExpiry
enabled
createdAt
updatedAt
```

### NotificationDelivery

```text
id
userId
documentId
reminderRuleId
channel: email | calendar
scheduledFor
sentAt optional
status: pending | sent | failed | cancelled
attemptCount
lastError optional
idempotencyKey unique
```

### CalendarConnection

```text
id
userId
provider
encryptedAccessToken
encryptedRefreshToken
scopes
connectedAt
revokedAt optional
```

### CalendarEvent

```text
id
userId
documentId
provider
externalEventId
status: active | deleted | failed
createdAt
updatedAt
```

## 9. Authentication and session policy

The session should feel persistent to the user without using an unlimited, permanently valid credential.

Recommended policy:

```text
Access token: 15–30 minutes
Refresh token: rotated on every refresh
Inactivity timeout: approximately 30 days
Maximum active sessions: 2
```

The Flutter client refreshes tokens silently. Refreshing a token must never end the user’s session or redirect them to login.

The user is sent to login when the session is expired, revoked, invalid, or explicitly logged out.

### Two-device rule

When a third session is created:

1. Create the new session.
2. Find the user’s active sessions ordered by `lastUsedAt`.
3. Revoke the oldest session.
4. Keep only the newest two active sessions.
5. Notify the removed client on its next protected request.

For immediate enforcement, protected API requests must verify that the session is active. A cache such as Redis can be introduced later; PostgreSQL is acceptable initially if performance is measured.

### Token safeguards

- Store only a hash of refresh tokens in the database.
- Never store authentication tokens in browser `localStorage` if secure HTTP-only cookies are practical for the web client.
- Use platform secure storage for native mobile clients.
- Use refresh-token rotation and replay detection.
- Revoke a session on logout.
- Revoke all sessions after a password reset or security event.
- Prevent concurrent refresh requests in Flutter with a single-flight refresh lock.
- Add rate limits to registration, login, refresh, and password-reset endpoints.

## 10. API design

### Authentication

```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/logout-all
GET  /api/auth/sessions
DELETE /api/auth/sessions/:id
```

### Documents

```http
GET    /api/documents
POST   /api/documents
GET    /api/documents/:id
PATCH  /api/documents/:id
DELETE /api/documents/:id
POST   /api/documents/:id/archive
```

### Reminders

```http
GET    /api/documents/:id/reminders
PUT    /api/documents/:id/reminders
```

### Calendar

```http
GET    /api/calendar/connect
GET    /api/calendar/callback
POST   /api/calendar/events
DELETE /api/calendar/events/:id
DELETE /api/calendar/connection
```

All resource queries must be scoped by the authenticated user or, in Phase 2, by an authorized family relationship. Never rely on a client-provided `userId` for authorization.

## 11. Flutter UI approach

Use an Apple-inspired glass design system with an original product identity. The visual system should include:

- Soft neutral background gradients
- Translucent surfaces
- Subtle blur and thin borders
- Large rounded corners
- Calm typography
- Clear status colors
- Minimal shadows
- Restrained motion
- Light and dark themes

Accessibility is more important than the glass effect. Every critical text element must remain readable, and the interface needs a solid-background fallback, high-contrast mode compatibility, reduced-motion support, and large touch targets.

### Primary screens

1. Welcome and authentication
2. Dashboard
3. Add item
4. Item details
5. Edit item
6. Reminder settings
7. Calendar connection
8. Profile and settings
9. Active sessions/device management

### Dashboard hierarchy

```text
Greeting
Attention summary
Expired and critical items
Expiring soon items
Upcoming and valid items
Add-item action
```

Desktop can use a navigation rail and wider card layout. Mobile should use a single-column layout and bottom navigation. The primary action to add an item must remain easy to reach on both layouts.

## 12. Implementation phases and exit criteria

### Step 1 — Foundation

Tasks:

- Create Flutter client
- Create TypeScript API
- Configure formatting, linting, environment loading, and testing
- Configure PostgreSQL and Prisma
- Add health/readiness endpoint
- Add CI build and test checks

Exit criteria:

- Client and server run independently
- Database migration succeeds
- Health endpoint responds correctly
- No secrets are committed

### Step 2 — Authentication and sessions

Tasks:

- Registration and login
- Password hashing
- Access and refresh tokens
- Silent refresh
- Refresh-token rotation
- Session storage and revocation
- Two-active-session limit
- Logout and logout-all
- Flutter auth guard

Exit criteria:

- User remains logged in through access-token refresh
- A third login revokes the oldest session
- Revoked sessions cannot access protected endpoints
- Concurrent refresh requests do not log the user out
- Authentication tests cover success and failure paths

### Step 3 — Document and subscription management

Tasks:

- Prisma models and migrations
- Create/read/update/archive/delete operations
- Server-side ownership checks
- Document type validation
- Subscription-specific required fields
- Expiry status calculation
- Pagination and filtering

Exit criteria:

- Users cannot access another user’s records
- Invalid subscription data is rejected
- Status boundaries are tested for 0, 7, 8, 30, 31, and 90 days
- All CRUD paths have API tests

### Step 4 — Dashboard and glass UI

Tasks:

- App theme and design tokens
- Responsive shell
- Authentication screens
- Dashboard cards and status groups
- Add/edit forms
- Detail screen
- Loading, empty, error, and success states
- Accessibility and reduced-motion behavior

Exit criteria:

- Desktop and mobile web layouts are usable
- Every visible primary action has a working route or API action
- Forms show server and validation errors clearly
- UI tests cover main navigation and item creation

### Step 5 — Reminder engine and email

Tasks:

- Reminder rule management
- Scheduled job generation
- Worker retry behavior
- Idempotency keys
- Email templates
- Delivery logging
- User notification preferences

Exit criteria:

- Each due reminder is delivered at most once per occurrence
- Failed delivery retries safely
- Time-zone behavior is tested
- Email configuration is documented through `.env.example`

### Step 6 — Google Calendar

Tasks:

- OAuth connection flow
- Secure encrypted token storage
- Create calendar event
- Update or delete event
- Disconnect behavior
- Expired OAuth-token handling

Exit criteria:

- Calendar is optional
- Users can connect and disconnect safely
- Calendar event IDs are persisted
- Removing an item does not leave unmanaged events without an explicit policy

### Step 7 — Release hardening

Tasks:

- Security review
- Dependency audit
- Rate limiting
- Structured logs without sensitive data
- Error monitoring
- Database backup plan
- Deployment configuration
- Production environment validation
- Browser and responsive QA

Exit criteria:

- Production build succeeds
- Database migrations are repeatable
- Secrets are externalized
- Critical API and UI flows have evidence-based verification
- Privacy policy and product disclaimer are ready

## 13. Testing strategy

### Backend

- Unit tests for expiry status and reminder calculations
- Unit tests for token/session policies
- API tests for authentication and ownership boundaries
- Integration tests against PostgreSQL
- Worker tests for idempotency and retry handling
- Calendar adapter tests using a fake provider

### Flutter

- Unit tests for models and validators
- Riverpod provider tests
- Widget tests for forms and dashboard states
- Navigation/auth-guard tests
- API client tests with fake responses
- Responsive layout checks at desktop and mobile widths

### Manual acceptance flows

- Register and log in
- Refresh the access token while staying on the dashboard
- Add an ID
- Add a driving license
- Add a subscription with provider and amount
- Reject an incomplete subscription
- Edit and archive an item
- Confirm each expiry status boundary
- Configure a reminder
- Connect and disconnect Google Calendar
- Log in from three sessions and confirm the oldest is removed
- Log out and confirm protected requests fail

## 14. Privacy and security principles

- Minimize stored personal data.
- Do not request document numbers or scans in the MVP.
- Hash passwords with a modern password-hashing algorithm.
- Hash refresh tokens at rest.
- Encrypt third-party OAuth tokens.
- Keep secrets only in environment or managed secret storage.
- Apply authorization on every resource endpoint.
- Avoid sensitive data in logs, analytics, and error messages.
- Provide account deletion and data export planning before production launch.
- Clearly state that the app is independent and not affiliated with government authorities.

## 15. Decisions still open

These decisions should be made before the relevant implementation step:

- Express versus Fastify
- Email provider
- Google OAuth application setup
- Exact refresh-token storage strategy for Flutter Web
- Exact inactivity timeout
- Whether calendar events are created only on request or automatically
- Product name and visual brand identity
- Deployment provider
- Whether subscriptions support custom billing intervals in the MVP

## 16. Recommended build order

Build the vertical slice in this order:

1. Foundation
2. Authentication and two-session enforcement
3. Add and display one document type
4. Complete all Phase 1 item types
5. Dashboard and visual system
6. Reminder worker and email
7. Calendar integration
8. Release hardening

The MVP is complete only when the main user journey works end to end: a user can register, add an item, see its calculated expiry status, configure reminders, stay logged in through token refresh, and receive the configured notification.
