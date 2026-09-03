process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/license_tracker?schema=public';
process.env.JWT_ACCESS_SECRET = 'test-access-secret-that-is-at-least-thirty-two-characters';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-that-is-at-least-thirty-two-characters';
process.env.COOKIE_SECURE = 'false';
process.env.GMAIL_CLIENT_ID = 'test-google-client-id';
process.env.GMAIL_CLIENT_SECRET = 'test-google-client-secret';
process.env.GMAIL_REFRESH_TOKEN = 'test-google-refresh-token';
process.env.EMAIL_FROM = 'DueNest <test@example.com>';
