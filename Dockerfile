ARG ELIXIR_VERSION=1.18.4
ARG ERLANG_VERSION=27.3.4.2
ARG ALPINE_VERSION=3.22.1

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS build

WORKDIR /app

RUN mix do local.hex --force, local.rebar --force

RUN apk add --no-cache \
    build-base \
    git

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# build app
COPY . .
RUN mix do compile, release

FROM alpine:${ALPINE_VERSION} AS release

RUN apk add --update --no-cache \
  libgcc \
  libstdc++ \
  ncurses-libs \
  make \
  curl

WORKDIR /app

COPY docker-entrypoint.sh ./
COPY --from=build /app/_build/prod/rel/* ./

ENTRYPOINT ["/app/docker-entrypoint.sh"]
