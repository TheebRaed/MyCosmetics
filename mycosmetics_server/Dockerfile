# Multi-stage Dart production Dockerfile
# Stage 1: Build
FROM dart:stable AS builder

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --no-precompile

COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Stage 2: Minimal runtime (no Dart SDK)
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/bin/server ./bin/server
COPY --from=builder /app/config ./config
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/web ./web 2>/dev/null || true

RUN chmod +x ./bin/server
RUN useradd -r -s /bin/false -u 1001 serverpod
USER serverpod

EXPOSE 8080 8081

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["./bin/server", "--mode", "production"]
