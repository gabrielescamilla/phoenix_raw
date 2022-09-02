FROM elixir:1.14-alpine as base

RUN apk upgrade --no-cache

RUN apk upgrade --no-cache \
    bash \
    build-base \
    coreutils \
    git \
    nodejs \
    npm \
    openssh-client

RUN mix local.rebar --force && mix local.hex --force

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan git.gabrielescamilla.com >> ~/.ssh/known_hosts
WORKDIR /app
COPY mix.exs .
COPY mix.lock .

RUN --mount=type=ssh mix deps.get
RUN MIX_ENV=test mix deps.compile
RUN MIX_ENV=prod mix deps.compile

COPY assets/package-lock.json assets/package-lock.json
COPY assets/package.json assets/package-json
RUN npm install --prefix ./assets --force
COPY . .

# Prepare for tests
FROM base as test
RUN npm run deploy --prefix ./assets
ENV TZ=EST5EDT

# Pack for prod
FROM base as builder

ENV NODE_ENV=production
ENV MIX_ENV=prod

RUN npm run deploy --prefix ./assets
RUN mix compile
RUN mix phx.digest
RUN mix release

# prod image from alpine
FROM elixir:1.14-alpine as prod

ENV APP_ENV_FILE=/etc/app/raw.json

RUN apk upgrade --no-cache && \
    apk add --no-cache bash tini && \
    adduser -D -h /app -u 400 deployer

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/app ./
COPY --from=builder /app/rel/script/* ./bin/
COPY --from=builder /app/REVISION ./
COPY --from=builder /app/*.pdf ./
RUN chown -R deployer:deployer /app

EXPOSE 4000 40001

USER deployer

ENTRYPOINT ["/sbin/tini", "--"]
CMD /app/bin/start.sh