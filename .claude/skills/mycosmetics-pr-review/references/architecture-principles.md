# MyCosmetics -- Architecture Principles & Rule Codes

Rule catalogue for `mycosmetics-pr-review`. Stack: Serverpod 2.2 (Dart) backend, Flutter 3.22 customer app + Flutter Web admin dashboard, PostgreSQL 16, Redis 7.

Source of truth for narrative context: `CLAUDE.md` (repo root), `docs/ARCHITECTURE.md`, `docs/API.md`, `docs/MAINTENANCE.md`.

---

## Backend layering (Serverpod)

| Code | Rule |
|---|---|
| `SPOD-01` | Endpoint methods (`lib/src/endpoints/*_endpoint.dart`) must not query the DB directly -- must call a `lib/src/business/*_service.dart` method, which uses a `lib/src/repositories/*_repository.dart`. |
| `SPOD-02` | Never hand-edit anything under `lib/src/generated/` -- protocol/model changes go through YAML in `lib/protocol/` then `serverpod generate`. |
| `SPOD-03` | Auth/permission checks must go through `AuthGuard.requirePermission()` -- not ad-hoc `if (user.role == ...)` in an endpoint or service. |
| `SPOD-04` | Session/token logic stays in `session_service.dart` -- don't inline Redis session reads/writes elsewhere. |
| `SPOD-05` | New migrations must be Serverpod-generated numbered folders under `migrations/` -- never a hand-written `.sql` file dropped in. |
| `SPOD-06` | `audit_logs` and `payment_audit_logs` are INSERT-only (Postgres RLS) -- any code path that UPDATEs or DELETEs a row in these tables is a critical violation. |
| `SPOD-07` | Validation belongs in the dedicated validators (`input_validator.dart`, `catalog_validator.dart`, `shopping_validator.dart`) -- not inlined in a service method as scattered `if` checks. |
| `SPOD-08` | Logging must go through `secure_logging.dart` -- raw `print()` of a request/response body, token, or password is critical. |
| `SPOD-09` | Endpoint action naming follows the POST-only RPC style documented in `docs/API.md` (`/domain/actionName`) -- don't introduce REST verb routing. |
| `SPOD-10` | Monetary fields use a precise decimal-safe type consistent with existing money fields in the same table -- flag a switch to `double` for a new monetary column. |

## Flutter clients (customer app + admin dashboard)

| Code | Rule |
|---|---|
| `FLT-01` | New screens/widgets go under `lib/features/{feature}/` (feature-first) -- not dumped in `lib/` root or an unrelated feature folder. |
| `FLT-02` | Shared/cross-cutting code (error handling, network client, router, theme) belongs in `lib/core/` or `lib/shared/` -- not duplicated per-feature. |
| `FLT-03` | API calls must go through the generated Serverpod client (`mycosmetics_client`) -- a raw `http.get`/`http.post`/`dio` call to a `mycosmetics` endpoint is critical. |
| `FLT-04` | No hardcoded secrets/API keys/base URLs in widget code -- must come from `core/network` config or environment. |
| `FLT-05` | Widget build methods doing business logic (score calculations, recommendation math) instead of delegating to a service/provider -- flag as a warning. |

## Cross-cutting

| Code | Rule |
|---|---|
| `SEC-01` | Rate limiting bypass -- a new endpoint that skips `rate_limiter.dart` where sibling endpoints in the same file apply it. |
| `SEC-02` | Webhook handlers (payment) must verify signature before processing -- missing verification is critical. |
| `TEST-01` | New service method in `lib/src/business/` with no corresponding test under `mycosmetics_server/test/` -- flag as a warning, matching the `auth_service_test.dart` pattern already in the repo. |

---

## Severity guidance

- **Critical** -- direct violation of a stated rule, security/data-integrity risk (e.g. `SPOD-02`, `SPOD-06`, `SEC-02`, raw DB query in an endpoint `SPOD-01`).
- **Warning** -- likely violation or correctness/consistency concern that needs attention but doesn't break anything yet (e.g. `TEST-01`, `FLT-05`, inconsistent monetary type `SPOD-10`).
- **Suggestion** -- improvement aligned with conventions but current code still works.

This file grows as real findings accumulate -- add new rule codes here as `mycosmetics-pr-review` discovers project-specific patterns.
