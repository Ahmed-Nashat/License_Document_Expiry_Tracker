import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const email = process.argv[2];

  if (!email) {
    console.error('Error: Please provide an email address.');
    console.error('Usage: npm run make-admin <email>');
    process.exit(1);
  }

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    console.error(`Error: User with email ${email} not found.`);
    process.exit(1);
  }

  if (user.role === 'ADMIN') {
    console.log(`User ${email} is already an ADMIN.`);
    process.exit(0);
  }

  await prisma.user.update({
    where: { email },
    data: { role: 'ADMIN' },
  });

  console.log(`Successfully elevated ${email} to ADMIN role.`);
}

main()
  .catch((e) => {
    console.error('An error occurred:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
