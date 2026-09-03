import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const expiryDate = new Date('2026-09-03T00:00:00.000Z');
const sendEmail = vi.fn().mockResolvedValue({ id: 'gmail-reminder-1' });
const mockPrisma = {
  systemConfig: {
    findUnique: vi.fn().mockResolvedValue(null),
    upsert: vi.fn().mockResolvedValue({}),
  },
  user: {
    findMany: vi.fn().mockResolvedValue([{
      id: 'user-1',
      email: 'person@example.com',
      displayName: 'Person',
      timeZone: 'Africa/Cairo',
      emailNotificationsEnabled: true,
      documents: [{
        id: 'doc-1',
        type: 'PASSPORT',
        expiryDate,
        isArchived: false,
        reminderRules: [{ daysBeforeExpiry: 0, enabled: true }],
      }],
    }]),
  },
  notificationLog: {
    upsert: vi.fn().mockResolvedValue({}),
    findMany: vi.fn().mockResolvedValue([{
      id: 'notification-1',
      documentId: 'doc-1',
      daysBefore: 0,
      targetExpiryDate: expiryDate,
      status: 'PENDING',
      retryCount: 0,
      user: {
        id: 'user-1',
        email: 'person@example.com',
        displayName: 'Person',
        emailNotificationsEnabled: true,
      },
      document: {
        id: 'doc-1',
        type: 'PASSPORT',
        expiryDate,
        isArchived: false,
        reminderRules: [{ daysBeforeExpiry: 0, enabled: true }],
      },
    }]),
    updateMany: vi.fn().mockResolvedValue({ count: 1 }),
    update: vi.fn().mockResolvedValue({}),
  },
};

vi.mock('../src/lib/prisma.js', () => ({ prisma: mockPrisma }));
vi.mock('../src/utils/mailer.js', () => ({ sendEmail }));

describe('reminder email regression', async () => {
  const { runReminderCycle } = await import('../src/modules/reminders/engine.js');

  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-09-03T06:00:00.000Z'));
    mockPrisma.systemConfig.findUnique.mockResolvedValue(null);
    mockPrisma.notificationLog.updateMany.mockResolvedValue({ count: 1 });
  });

  afterEach(() => vi.useRealTimers());

  it('continues to deliver due reminder emails through the mailer', async () => {
    await runReminderCycle();

    expect(mockPrisma.notificationLog.upsert).toHaveBeenCalledOnce();
    expect(sendEmail).toHaveBeenCalledWith(expect.objectContaining({
      to: 'person@example.com',
      subject: 'Reminder: PASSPORT expires today',
    }));
    expect(mockPrisma.notificationLog.update).toHaveBeenCalledWith({
      where: { id: 'notification-1' },
      data: { status: 'SENT', sentAt: expect.any(Date), processingAt: null, error: null },
    });
  });
});
