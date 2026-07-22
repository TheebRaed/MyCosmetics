# MyCosmetics -- CLAUDE.md

BeautyTech e-commerce platform. Serverpod (Dart) backend + two Flutter clients (customer app, admin dashboard).

## Stack

| Component | Technology |
|---|---|
| Customer App | Flutter 3.22 (iOS + Android) -- `mycosmetics_flutter/` |
| Admin Dashboard | Flutter 3.22 (Web) -- `mycosmetics_admin/` |
| API Server | Serverpod 2.x (Dart) -- `mycosmetics_server/` |
| Database | PostgreSQL 16 (single provider, no multi-DB abstraction) |
| Session store | Redis 7 (bearer UUID tokens, not JWT) |
| Reverse proxy | Nginx |

Full narrative docs: `docs/ARCHITECTURE.md`, `docs/API.md`, `docs/DEPLOYMENT.md`, `docs/MAINTENANCE.md`, `docs/LAUNCH_CHECKLIST.md`.

## Backend layering (non-negotiable)

```
lib/src/endpoints/*_endpoint.dart   -- thin, extends Endpoint, no direct DB access
        v
lib/src/business/*_service.dart     -- business logic, orchestrates repositories
        v
lib/src/repositories/*_repository.dart -- DB access only
```

- Protocol/DTOs are YAML under `lib/protocol/`, code-generated into `lib/src/generated/` via `serverpod generate`. **Never hand-edit generated files.**
- Auth is Redis-backed bearer UUID tokens (7-day sliding), not JWT. Permission checks go through `AuthGuard.requirePermission()` -- never ad-hoc role checks.
- Migrations are Serverpod-generated numbered folders under `migrations/`. Never hand-write a migration SQL file.
- `audit_logs` and `payment_audit_logs` are **INSERT-only** (Postgres RLS) -- never add UPDATE/DELETE paths to them.
- Validation lives in `lib/src/utils/{input_validator,catalog_validator,shopping_validator}.dart` -- extend these, don't inline ad-hoc checks in a service.
- Logging goes through `lib/src/utils/secure_logging.dart` -- never `print()` a request/response body, token, or password.
- API endpoints are **POST-only RPC style** (`/domain/actionName`), not REST verbs -- see `docs/API.md` for the existing contract.
- Payment webhook handlers must verify the provider signature before processing anything.

## Flutter clients (both apps)

- **Feature-first** folders: `lib/features/{feature}/`. Shared code in `lib/core/` (`error`, `network`, `router`, `theme`) or `lib/shared/`.
- API calls go through the generated Serverpod client (`mycosmetics_client`) -- never a raw `http`/`dio` call against these endpoints.
- `mycosmetics_admin` is the mature reference for feature-folder conventions (`analytics`, `audit`, `coupons`, `customers`, `dashboard`, `inventory`, `notifications`, `orders`, `products`, `reports`).
- `mycosmetics_flutter` (customer app) has no populated `lib/` yet as of this handoff -- confirm scope before assuming existing screen conventions there.

## Agents

This repo ships a project-local agent fleet under `.claude/agents/`:

| Agent | Role |
|---|---|
| `mycosmetics-orchestrator` | Multi-layer feature coordinator -- use for anything touching backend + a client, or backend + payments/security |
| `mycosmetics-backend` | Serverpod: protocol, repository, service, endpoint, migrations |
| `mycosmetics-flutter` | Both Flutter clients: screens, widgets, state, generated-client wiring |
| `mycosmetics-security` | Auth, sessions, RBAC, payment webhooks, rate limiting, audit/RLS tables |
| `mycosmetics-devops` | Docker, Nginx, deployment, backups, monitoring |
| `mycosmetics-testing` | Dart/Flutter unit + service tests |

Two project-local skills under `.claude/skills/`:
- `mycosmetics-new-task` -- task briefing, run before starting any new feature/fix
- `mycosmetics-pr-review` -- PR-style review of a branch against these standards

## Golden rules

1. Endpoints never touch the DB directly.
2. Never hand-edit `lib/src/generated/`.
3. Never hand-write a migration file.
4. Never bypass `AuthGuard` for permission checks.
5. Never let `audit_logs` / `payment_audit_logs` be updated or deleted.
6. Never call a `mycosmetics` endpoint with raw `http`/`dio` from a client -- use the generated client.
