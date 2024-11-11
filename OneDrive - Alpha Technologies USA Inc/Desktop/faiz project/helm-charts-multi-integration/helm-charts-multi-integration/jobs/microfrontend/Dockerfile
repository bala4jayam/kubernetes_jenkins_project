FROM node:20-slim AS catalog
RUN npm install -g pnpm
WORKDIR /app
COPY ./catalog /app
RUN pnpm install && pnpm run build

FROM node:20-slim AS platform
RUN npm install -g pnpm
WORKDIR /app
COPY ./platform /app
RUN pnpm install && pnpm run build

FROM node:20-slim AS registry
RUN npm install -g pnpm
WORKDIR /app
COPY ./registry /app
RUN pnpm install && pnpm run build

FROM nginx:alpine

COPY --from=catalog /app/dist /usr/share/nginx/html/catalog
COPY --from=platform /app/dist /usr/share/nginx/html/platform
COPY --from=registry /app/dist /usr/share/nginx/html/registry

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]