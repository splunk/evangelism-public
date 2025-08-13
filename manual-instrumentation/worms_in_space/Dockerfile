FROM node:10-alpine AS worms-in-space-npm
WORKDIR /app/npm
COPY ./assets/package.json /app/npm/package.json
COPY ./assets/package-lock.json /app/npm/package-lock.json
RUN npm install

FROM elixir:1.14-alpine
WORKDIR /app
COPY ./assets /app/assets
COPY ./lib /app/lib
COPY ./test /app/test
COPY ./config /app/config
COPY ./scripts /app/scripts
COPY ./mix.exs /app/mix.exs
COPY --from=worms-in-space-npm /app/npm/node_modules /app/node_modules
RUN apk add inotify-tools postgresql-client
RUN chmod +x /app/scripts/start.sh
RUN mix local.hex --force && mix local.rebar --force && mix do deps.get, compile
EXPOSE 4000