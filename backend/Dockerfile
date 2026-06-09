# Stage 1: Install all deps (including dev)
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Build (uncomment if using TypeScript)
FROM deps AS builder
WORKDIR /app
COPY . .
# RUN npm run build

# Stage 3: Production image (only prod deps + source)
FROM node:20-alpine AS production
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app .

EXPOSE 5000

USER node

CMD ["node", "index.js"]