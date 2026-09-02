

import cron from 'node-cron';
import { prisma } from '../../lib/prisma.js';
import { sendEmail } from '../../utils/mailer.js';

const DAY_MS = 24 * 60 * 60 * 1000;

function escapeHtml(value: string): string {
  return value.replace(/[&<>'"]/g, (character) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  })[character] ?? character);
}

function getDateParts(timeZone: string, date = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  const parts = formatter.formatToParts(date);
  return {
    year: Number(parts.find((part) => part.type === 'year')?.value),
    month: Number(parts.find((part) => part.type === 'month')?.value) - 1,
    day: Number(parts.find((part) => part.type === 'day')?.value),
  };
}

function isUserLocalHour(timeZone: string, targetHour: number): boolean {
  try {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone,
      hour: 'numeric',
      hourCycle: 'h23',
    });
    return Number(formatter.format(new Date())) === targetHour;
  } catch {
    return new Date().getUTCHours() === targetHour;
  }
}

function getDaysUntilExpiry(expiryDate: Date, timeZone: string): number {
  try {
    const today = getDateParts(timeZone);
    const todayUtc = Date.UTC(today.year, today.month, today.day);
    const expiryUtc = Date.UTC(
      expiryDate.getUTCFullYear(),
      expiryDate.getUTCMonth(),
      expiryDate.getUTCDate(),
    );
    return Math.round((expiryUtc - todayUtc) / DAY_MS);
  } catch {
    const now = new Date();
    const todayUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
    const expiryUtc = Date.UTC(
      expiryDate.getUTCFullYear(),
      expiryDate.getUTCMonth(),
      expiryDate.getUTCDate(),
    );
    return Math.round((expiryUtc - todayUtc) / DAY_MS);
  }
}

async function generateReminders() {
  // Check if the engine has been paused by an admin
  const pauseFlag = await prisma.systemConfig.findUnique({ where: { key: 'REMINDER_ENGINE_PAUSED' } });
  if (pauseFlag?.value === 'true') {
    console.log('[ReminderEngine] Engine is paused. Skipping generateReminders.');
    return;
  }

  // Record last run timestamp
  await prisma.systemConfig.upsert({
    where: { key: 'REMINDER_ENGINE_LAST_RUN' },
    update: { value: new Date().toISOString(), updatedById: 'SYSTEM', reason: 'Automatic engine run' },
    create: { key: 'REMINDER_ENGINE_LAST_RUN', value: new Date().toISOString(), updatedById: 'SYSTEM', reason: 'Automatic engine run' },
  });

  const users = await prisma.user.findMany({
    include: {
      documents: {
        where: { isArchived: false },
        include: { reminderRules: { where: { enabled: true } } },
      },
    },
  });

  for (const user of users) {
    if (!user.emailNotificationsEnabled || !isUserLocalHour(user.timeZone, 9)) continue;

    for (const doc of user.documents) {
      const daysUntil = getDaysUntilExpiry(doc.expiryDate, user.timeZone);
      if (daysUntil < 0) continue;

      for (const rule of doc.reminderRules) {
        if (daysUntil !== rule.daysBeforeExpiry) continue;

        await prisma.notificationLog.upsert({
          where: {
            documentId_daysBefore_targetExpiryDate: {
              documentId: doc.id,
              daysBefore: rule.daysBeforeExpiry,
              targetExpiryDate: doc.expiryDate,
            },
          },
          create: {
            documentId: doc.id,
            userId: user.id,
            daysBefore: rule.daysBeforeExpiry,
            targetExpiryDate: doc.expiryDate,
            status: 'PENDING',
          },
          update: {},
        });
      }
    }
  }
}

async function dispatchReminders() {
  const pauseFlag = await prisma.systemConfig.findUnique({ where: { key: 'REMINDER_ENGINE_PAUSED' } });
  if (pauseFlag?.value === 'true') {
    console.log('[ReminderEngine] Engine is paused. Skipping dispatchReminders.');
    return;
  }

  const processingCutoff = new Date(Date.now() - 15 * 60 * 1000);
  const pendingLogs = await prisma.notificationLog.findMany({
    where: {
      OR: [
        { status: 'PENDING' },
        { status: 'FAILED', retryCount: { lt: 3 } },
        { status: 'PROCESSING', processingAt: { lt: processingCutoff } },
      ],
    },
    include: {
      user: true,
      document: { include: { reminderRules: { where: { enabled: true } } } },
    },
    take: 50,
  });

  for (const log of pendingLogs) {
    const hasActiveRule = log.document.reminderRules.some(
      (rule) => rule.daysBeforeExpiry === log.daysBefore,
    );
    const isCurrent =
      !log.document.isArchived &&
      log.user.emailNotificationsEnabled &&
      log.document.expiryDate.getTime() === log.targetExpiryDate.getTime() &&
      hasActiveRule;
    if (!isCurrent) {
      await prisma.notificationLog.update({
        where: { id: log.id },
        data: {
          status: 'FAILED',
          retryCount: 3,
          processingAt: null,
          error: 'Notification is no longer applicable.',
        },
      });
      continue;
    }

    const claimed = await prisma.notificationLog.updateMany({
      where: {
        id: log.id,
        status: log.status,
        retryCount: { lt: 3 },
        ...(log.status === 'PROCESSING'
          ? { processingAt: { lt: processingCutoff } }
          : {}),
      },
      data: { status: 'PROCESSING', processingAt: new Date() },
    });
    if (claimed.count !== 1) continue;

    try {
      const dueText = log.daysBefore === 0 ? 'today' : `in ${log.daysBefore} days`;
      const html = `<h2>Document Expiry Reminder</h2>
        <p>Hi ${escapeHtml(log.user.displayName ?? 'there')},</p>
        <p>Your document <strong>${escapeHtml(log.document.type)}</strong> is expiring ${dueText}.</p>
        <p>Please log in to DueNest to renew or update it.</p>`;

      await sendEmail({
        to: log.user.email,
        subject: `Reminder: ${log.document.type} expires ${dueText}`,
        html,
      });

      await prisma.notificationLog.update({
        where: { id: log.id },
        data: { status: 'SENT', sentAt: new Date(), processingAt: null, error: null },
      });
    } catch (error) {
      await prisma.notificationLog.update({
        where: { id: log.id },
        data: {
          status: 'FAILED',
          processingAt: null,
          error: error instanceof Error ? error.message : 'Unknown error',
          retryCount: { increment: 1 },
        },
      });
    }
  }
}

export function startReminderEngine() {
  cron.schedule('0 * * * *', async () => {
    try {
      await generateReminders();
      await dispatchReminders();
    } catch (error) {
      console.error('[Reminder Engine] Scheduled run failed:', error);
    }
  });

  // Avoid running the dispatcher twice at the top of each hour.
  cron.schedule('5,20,35,50 * * * *', async () => {
    try {
      await dispatchReminders();
    } catch (error) {
      console.error('[Reminder Engine] Dispatcher run failed:', error);
    }
  });
}
