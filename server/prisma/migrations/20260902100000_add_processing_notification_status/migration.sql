ALTER TYPE "NotificationStatus" ADD VALUE 'PROCESSING';
ALTER TABLE "NotificationLog" ADD COLUMN "processingAt" TIMESTAMP(3);
