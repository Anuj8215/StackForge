# Stage 1: Install all deps (including dev)
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Copy source
FROM deps AS builder
WORKDIR /app
COPY . .

# Stage 3: Production image
FROM node:20-alpine AS production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app .
EXPOSE 4000
USER node
CMD ["node", "server.js"]