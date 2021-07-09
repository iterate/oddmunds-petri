FROM bitwalker/alpine-elixir-phoenix:1.10.2 AS phx-builder

ENV MIX_ENV=prod

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

ADD assets/package.json assets/
ADD assets/package-lock.json assets/
RUN cd assets && \
    npm install

ADD . .

# Run frontend build, compile, and digest assets
RUN cd assets/ && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest

FROM bitwalker/alpine-elixir:latest

EXPOSE 3000
ENV PORT=3000 MIX_ENV=prod

COPY --chown=default --from=phx-builder /opt/app/_build /opt/app/_build
COPY --chown=default --from=phx-builder /opt/app/priv /opt/app/priv
COPY --chown=default --from=phx-builder /opt/app/config /opt/app/config
COPY --chown=default --from=phx-builder /opt/app/lib /opt/app/lib
COPY --chown=default --from=phx-builder /opt/app/deps /opt/app/deps
# COPY --from=phx-builder /opt/app/.mix /opt/app/.mix
COPY --chown=default --from=phx-builder /opt/app/mix.* /opt/app/

# tz stuff from adrian en to tre
COPY --chown=default --from=phx-builder /opt/app/_build/prod/lib/tzdata/priv/release_ets /timezone_db/

USER default

CMD ["mix", "phx.server"]