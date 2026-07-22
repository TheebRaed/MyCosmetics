# MyCosmetics Reviewer Checklist

Starting checklist (from `CLAUDE.md` + repo layout) -- verify before flagging, extend as the codebase grows.

- Endpoint methods must not query the DB directly -- must go through a repository via a service.
- No hand-edits inside `lib/src/generated/` -- protocol changes go through the YAML in `lib/protocol/`.
- Auth checks use `AuthGuard.requirePermission()` -- not ad-hoc `if (user.role == ...)` checks.
- `audit_logs` / `payment_audit_logs` -- INSERT-only, never add UPDATE/DELETE.
- No raw `print()` of request/response bodies -- use `secure_logging.dart`.
- New migrations are Serverpod-generated numbered folders -- never hand-written SQL files dropped into `migrations/`.
- Client apps call the generated `mycosmetics_client` -- never raw `http`/`dio` against these endpoints.
- Payment webhook handlers verify the provider signature before processing.
- New backend service methods have a corresponding test under `mycosmetics_server/test/`.
