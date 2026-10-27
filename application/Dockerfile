FROM node:22-slim
WORKDIR /cloudsave

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 4000
CMD ["npm", "start"]
