FROM node:14-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

# FROM node:14-alpine

COPY . .

# COPY --from=builder . .

EXPOSE 3000

CMD [ "node", "index.js" ]
