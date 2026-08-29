

A privacy-first web application for tracking document expiration dates and receiving reminders before they expire.

Features

- User authentication
- Track document expiration dates
- Expiry status dashboard
- Custom reminder schedules
- Email notifications
- Google Calendar integration
- Custom document types

Supported Documents

- National ID
- Driving License
- Passport
- Vehicle License
- Vehicle Insurance
- Custom Documents

Privacy

The application follows a data-minimization approach.

Stored

- Document type
- Expiration date
- Optional nickname
- Reminder preferences

Not Required

- National ID numbers
- Passport numbers
- Driving license numbers
- Document scans or photos

Tech Stack

Frontend

- React
- TypeScript
- Tailwind CSS

Backend

- Node.js
- Express
- PostgreSQL
- Prisma ORM

Integrations

- Google Calendar API
- Email notifications

Project Structure

license-tracker/
├── client/
│   └── src/
│       ├── components/
│       ├── pages/
│       ├── hooks/
│       ├── services/
│       └── types/
├── server/
│   ├── src/
│   │   ├── controllers/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── middleware/
│   │   ├── jobs/
│   │   └── utils/
│   └── prisma/
│       └── schema.prisma
├── .env.example
├── .gitignore
└── README.md

API

Authentication

POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh

Documents

GET    /api/documents
POST   /api/documents
GET    /api/documents/:id
PATCH  /api/documents/:id
DELETE /api/documents/:id

Calendar

GET    /api/calendar/connect
POST   /api/calendar/events
DELETE /api/calendar/events/:id

Expiry Status

Status| Time Remaining
Expired| 0 days or less
Critical| 1–7 days
Expiring Soon| 8–30 days
Upcoming| 31–90 days
Valid| 90+ days

Default Reminders

- 90 days before expiration
- 30 days before expiration
- 7 days before expiration
- 1 day before expiration
- Expiration day

Disclaimer

This application is an independent document reminder tool and is not affiliated with or endorsed by any government authority.