# Stage 1 - Build dependencies
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .


# Stage 2 - Minimal production runtime
FROM node:20-alpine

WORKDIR /app

RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx

COPY --from=builder /app /app

EXPOSE 8080

CMD ["node", "app.js"]