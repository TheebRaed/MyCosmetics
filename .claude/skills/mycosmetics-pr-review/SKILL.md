---
name: mycosmetics-pr-review
description: Perform a Pull-Request style code review of the current branch against a base branch for the MyCosmetics BeautyTech platform -- Serverpod (Dart) backend + Flutter clients. Scans only changed files, emits inline comments on added/modified lines only, checked against Serverpod layering, generated-code, auth, and Flutter conventions. Use whenever asked to review a branch/PR on this repo -- "review my branch", "review my PR", "check my changes", and Arabic equivalents ("راجع البرانش", "اعمل ريفيو"). Do NOT use for new features (use mycosmetics-new-task) or commit messages.
---

# MyCosmetics PR Review

Pull-Request-style code review against the MyCosmetics architecture (Serverpod backend + Flutter clients).
Scans only changed files (vs. user-supplied base branch), emits inline comments on added/modified lines only.

---

## Step 0 -- Confirm project + read rules

Confirm this is the mycosmetics repo (look for `mycosmetics_server/pubspec.yaml` with a `serverpod:` dependency, and/or `mycosmetics_admin/`, `mycosmetics_flutter/` at repo root). If not, stop and say so.

Read `CLAUDE.md` (repo root) and `references/architecture-principles.md` before proceeding.

**Key conventions:**

| Check | Rule |
|---|---|
| Backend layering | Endpoint -> Service -> Repository -- endpoints never touch the DB directly (`SPOD-01`) |
| Generated code | Never hand-edit `lib/src/generated/` (`SPOD-02`) |
| Auth | `AuthGuard.requirePermission()`, Redis bearer tokens (`SPOD-03`) |
| Migrations | Serverpod-generated numbered folders only (`SPOD-05`) |
| Audit tables | `audit_logs` / `payment_audit_logs` INSERT-only (`SPOD-06`) |
| Logging | Through `secure_logging.dart` only (`SPOD-08`) |
| Flutter structure | Feature-first `lib/features/{feature}/` (`FLT-01`, `FLT-02`) |
| Flutter API calls | Only via generated `mycosmetics_client` (`FLT-03`) |

---

## Step 1 -- Ask for base branch

Always ask the user **once** which base branch to compare against. Do not assume `main`.

---

## Step 2 -- Verify git state

```bash
git rev-parse --is-inside-work-tree
git rev-parse --abbrev-ref HEAD
git fetch --all --quiet
git rev-parse --verify <base-branch>
```

If any fail, stop and tell the user (not a git repo, base branch doesn't exist, etc.).

---

## Step 3 -- Collect changed files and diffs

```bash
git diff --name-status <base>...HEAD
git diff --unified=0 <base>...HEAD -- <file>
```

- Skip pure deletions (`D`) and content-free renames (`R100`).
- Parse only added lines (`+`, not `+++` headers) and their new-file line numbers from hunk headers.

---

## Step 4 -- Determine review scope per file

| Path / extension pattern | Apply rules |
|---|---|
| `mycosmetics_server/lib/src/endpoints/*_endpoint.dart` | `SPOD-01`, `SPOD-03`, `SPOD-09`, `SEC-01` |
| `mycosmetics_server/lib/src/business/*_service.dart` | `SPOD-01`, `SPOD-03`, `SPOD-06`, `SPOD-07`, `SPOD-10`, `TEST-01` |
| `mycosmetics_server/lib/src/repositories/*_repository.dart` | `SPOD-01`, `SPOD-06` |
| `mycosmetics_server/lib/src/generated/**` | `SPOD-02` (flag critical unless a matching protocol YAML change is also in the diff) |
| `mycosmetics_server/lib/protocol/**` | confirm a matching `generated/` regen is included |
| `mycosmetics_server/migrations/**` | `SPOD-05` |
| `mycosmetics_server/lib/src/endpoints/payment_endpoint.dart`, `business/payment_service.dart` | `SEC-02` plus standard backend rules |
| Any diff line containing `print(` in `mycosmetics_server/**` | `SPOD-08` |
| `mycosmetics_admin/lib/**`, `mycosmetics_flutter/lib/**` | `FLT-01` through `FLT-05` |
| `mycosmetics_server/test/**` | naming/coverage sanity only, no blocking rule |

If a file falls outside all categories (docs, nginx config, CI), scan lightly for obvious secrets/credentials but keep comments minimal.

---

## Step 5 -- Run the review per file, per added line

Check added lines against `references/architecture-principles.md`. Use rule codes (`SPOD-01`, `FLT-03`, etc.) so comments are traceable.

For each finding: **File**, **Line** (the `+` line number), **Severity** (Critical/Warning/Suggestion), **Rule** code, **Comment** (short, explains problem + fix).

**Critical** -- `SPOD-02`, `SPOD-06`, `SEC-02`, `SPOD-01`, `FLT-03`.
**Warning** -- `TEST-01`, `FLT-05`, `SPOD-10`, `SEC-01`.
**Suggestion** -- style/consistency improvements that don't break anything.

---

## Step 6 -- Output format

```
## PR Review -- <branch-name> vs <base-branch>

**Summary:** <N> files changed - <C> Critical - <W> Warning - <S> Suggestion

---

### `<relative/path/to/file.dart>`

CRITICAL - Line 42 - `SPOD-01`
> This endpoint method queries the repository directly. Route this through the service instead.

WARNING - Line 58 - `TEST-01`
> New method has no corresponding test. Add a case mirroring `auth_service_test.dart`.

---
```

- One comment per finding; line numbers only from added (`+`) lines.
- Clean files are omitted, reflected only in the summary line.
- End with: `<K> files clean - <M> files with findings`.
- If zero findings: `No principle violations found on the changed lines.`

---

## Step 7 -- Don't go beyond the diff

Never comment on lines not in the diff, except a single Suggestion-level note when an added line depends on clearly broken surrounding code.

---

## Reference

Full rule catalogue in `references/architecture-principles.md`. Refer to rules by code in every comment.
