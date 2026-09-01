FROM node:24.18.0-alpine AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM dependencies AS build
COPY prisma ./prisma
RUN npx prisma generate
COPY tsconfig.json eslint.config.js ./
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:24.18.0-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S -g 10001 appgroup && adduser -S -D -u 10001 -G appgroup appuser
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./package.json
COPY --from=build --chown=appuser:appgroup /app/prisma ./prisma
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
USER appuser
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
