# Use a more secure base - bookworm-slim has better security patches than alpine
FROM node:22-bookworm-slim AS builder
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:22-bookworm-slim AS production
RUN apt-get update && apt-get install -y --no-install-recommends dumb-init && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r nodejs -g 1001 && useradd -r -g nodejs -u 1001 nodejs

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY backend/src ./src
COPY backend/package.json .

RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["dumb-init", "node", "src/index.js"]
