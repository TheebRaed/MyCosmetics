# Multi-stage Dart production Dockerfile
# Build context is the repo root (not this directory), because the server
# depends on the generated ../mycosmetics_client package via a path
# dependency: docker build -f mycosmetics_server/Dockerfile .
FROM dart:stable AS builder

WORKDIR /repo
COPY mycosmetics_client ./mycosmetics_client
COPY mycosmetics_server ./mycosmetics_server

WORKDIR /repo/mycosmetics_server
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Stage 2: Minimal runtime (no Dart SDK)
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /repo/mycosmetics_server/bin/server ./bin/server
COPY --from=builder /repo/mycosmetics_server/config ./config
COPY --from=builder /repo/mycosmetics_server/migrations ./migrations

RUN chmod +x ./bin/server
RUN useradd -r -s /bin/false -u 1001 serverpod
USER serverpod

EXPOSE 8080 8081

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["./bin/server", "--mode", "production"]
