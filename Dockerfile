FROM node:20-alpine

WORKDIR /app

RUN apk update && apk upgrade --no-cache

COPY package*.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY . .

EXPOSE 8080

CMD ["npm", "start"]