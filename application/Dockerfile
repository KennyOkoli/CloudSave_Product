FROM node:22-slim AS builder
WORKDIR /cs

COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-slim
WORKDIR /cloudsave
COPY --from=builder /cs/node_modules ./node_modules
COPY . .
CMD ["npm","run","start"]
