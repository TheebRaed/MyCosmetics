---
name: mycosmetics-new-task
description: MyCosmetics BeautyTech platform task briefing -- Serverpod (Dart) backend + Flutter customer app + Flutter Web admin dashboard. Detects which app/layer and domain area a task touches, loads the relevant project docs BEFORE writing code, and delegates to the project's mycosmetics-* agent fleet so output is compliant on the first try. Use whenever starting a new task, feature, endpoint, screen, or widget on this platform. Triggers on "let's build X", "implement Y", "add Z", "fix ...", any pasted user story or ticket targeting the backend, the customer app, or the admin dashboard, and Arabic equivalents ("بدي اعمل", "ضيف صفحة", "اعملي endpoint"). Do NOT use for reviewing existing code/PRs (use mycosmetics-pr-review).
---

# MyCosmetics -- New Task Briefing

Code that matches the existing Serverpod/Flutter conventions and passes review on the first try is the only acceptable output.

Read `CLAUDE.md` at the repo root first if you haven't already this session -- it has the non-negotiable golden rules for this codebase.

---

## Step 0 -- Check skill memory (silent)

Read `memory/MEMORY.md` if it exists (relative to this skill's folder). If any topic file is relevant to this task, read it too. Apply silently.

---

## Step 0.5 -- Detect Handoff Mode

**Check FIRST -- if triggered, skip Steps 1-6.**

Trigger if the message contains ANY of: "handoff", "new chat", "switch chat", "resume prompt", "بدي اروح شات جديد", "شات جديد", "اعطيني برومت".

**If triggered -> run these steps then STOP:**

1. Read `memory/MEMORY.md` + any topic files relevant to what was worked on this chat.
2. Extract: which app/layer + domain area, what task, what was completed, what's pending, key decisions, gotchas.
3. Generate a resume prompt:
   ```
   /mycosmetics-new-task

   **Handoff from previous chat -- MyCosmetics:**

   App/Layer: [e.g. Serverpod backend -- Coupon service, or Admin dashboard -- Inventory feature]
   Task: [brief description]

   **Completed:**
   - [item]

   **In progress / Next step:**
   - [what to continue]

   **Key decisions:**
   - [decision]

   **Watch out for:**
   - [gotcha or constraint]
   ```
4. Save it to `handoffs/{NNNNNN}-{DD.MM.YYYY}-{ShortName}.md` (relative to this skill's folder; read `handoffs/index.md` for the next sequence number, start at `000001` if none). Append a row to `handoffs/index.md` (create with a header if missing).
5. Tell the user where the file was saved and to paste its contents into the new chat.

---

## Step 1 -- Detect app/layer + domain area + scope

### A. Which app/layer?

| Keyword / Domain | App/Layer | Path |
|---|---|---|
| endpoint, API, backend, server, serverpod, migration, redis, postgres | **Server (backend)** | `mycosmetics_server/` |
| customer app, shopping, checkout, beautytech, virtual try-on, skin analysis | **Customer App (Flutter)** | `mycosmetics_flutter/` |
| admin, dashboard, inventory, reports, analytics, audit | **Admin Dashboard (Flutter Web)** | `mycosmetics_admin/` |
| auth, login, permission, session, payment, webhook, rate limit, audit log | **Security (cross-cutting)** | see `mycosmetics-security` agent |
| nginx, docker, deploy, ssl, backup | **Infra** | `nginx/`, `docker-compose.prod.yml`, `scripts/` |

Most real features touch backend + one client. If ambiguous, ask one focused question or default to "server + the client that owns the UI for it".

### B. Which domain area? (mirrors the server's endpoint/service naming)

| Keyword | Area | Server files |
|---|---|---|
| login, register, password, token, session | Auth | `auth_endpoint.dart`, `auth_service.dart` -> delegate security-sensitive parts to `mycosmetics-security` |
| profile, address | Profile | `profile_endpoint.dart`, `profile_service.dart` |
| product, variant, category, brand, catalog, search | Catalog | `product*_endpoint.dart`, `category_endpoint.dart`, `brand_endpoint.dart` |
| cart, coupon, discount | Cart & Coupons | `cart_endpoint.dart`, `cart_service.dart`, `coupon_service.dart` |
| order, checkout, shipping | Orders | `order_endpoint.dart`, `order_service.dart`, `shipping_service.dart` |
| payment, webhook, refund | Payments | `payment_endpoint.dart`, `payment_service.dart` -> delegate signature/idempotency to `mycosmetics-security` |
| review, wishlist | Reviews & Wishlist | `review_endpoint.dart`, `wishlist_endpoint.dart` |
| beautytech, skin tone, tryon, recommendation, shade | BeautyTech | search `lib/src/endpoints/` and `migrations/00000000000003-beautytech/` -- confirm exact filenames, this area evolves |
| admin, audit log, stock adjustment, notification campaign | Admin/Ops | `admin_endpoint.dart`, `admin_service.dart` |

For the Admin Dashboard, mirror the domain word to `mycosmetics_admin/lib/features/{analytics,audit,coupons,customers,dashboard,inventory,notifications,orders,products,reports}/`.
For the Customer App, check whether `mycosmetics_flutter/lib/` exists yet -- if not, confirm scope before assuming structure (it's a greenfield app as of this handoff).

### C. What scope?

| Scope | Signal words | Output mode |
|---|---|---|
| `full` | "build", "create", "new endpoint + UI", "CRUD" | Full vertical slice via the agent chain |
| `partial` | "add endpoint", "add screen", "add widget" | 2-3 layers only -- state which up front |
| `micro` | "fix", "rename", "change X to Y" | Affected file(s) only, built directly, no agent hop |

---

## Step 2 -- Load context (silent, smart)

### Always load
- `CLAUDE.md` (repo root)
- `references/domain-traps.md` (this skill)
- `references/reviewer.md` (this skill)

### Load for `full`/`partial` backend tasks
- `docs/API.md`
- `mycosmetics_server/lib/src/generated/README.md`

### Load for anything touching payments, deploy, or migrations
- `docs/DEPLOYMENT.md`, `docs/MAINTENANCE.md`, `docs/LAUNCH_CHECKLIST.md`

### Load per detected domain area
The relevant server files from the Step 1B table, plus the mirrored client feature folder.

### Skip rules
- `micro` -> only `CLAUDE.md` + `domain-traps.md` + the one affected file
- Backend-only -> skip client feature folders
- Client-only (copy/widget tweak) -> skip `docs/API.md` and server business/repository files

---

## Step 3 -- Pre-flight (silent)

Verify mentally before writing code -- see `CLAUDE.md` for the full golden-rules list. Highlights:
- Endpoint -> Service -> Repository, endpoints never touch the DB directly
- Never hand-edit `lib/src/generated/`
- Auth via `AuthGuard.requirePermission()`, Redis bearer tokens
- Migrations are Serverpod-generated, never hand-written SQL
- `audit_logs` / `payment_audit_logs` are INSERT-only
- Flutter: feature-first folders, API calls only via the generated `mycosmetics_client`

`references/domain-traps.md` -- apply silently.

---

## Step 4 -- Delegate to the agent fleet

### For `full` or `partial` scope

Use the Agent tool to launch the relevant `mycosmetics-*` agent(s) from `.claude/agents/`:

| Situation | Agent(s) to launch |
|---|---|
| Touches backend + a client (most `full` features) | `mycosmetics-orchestrator` -- give it the task + Step 1/2 context, let it plan and delegate the rest |
| Backend only | `mycosmetics-backend` directly |
| Client UI only (one app) | `mycosmetics-flutter` directly |
| Auth/permissions/payments/rate-limiting/audit | `mycosmetics-security` (in addition to backend/flutter if data/UI changes are also needed) |
| Deploy/Docker/Nginx/backup/monitoring | `mycosmetics-devops` directly |
| Tests only, or as a trailing step after another agent | `mycosmetics-testing` |

Pass each agent: the verbatim task, the app/layer + domain area from Step 1, and the context loaded in Step 2. Let the agent do the actual implementation -- this skill's job is routing and context-loading, not writing the code itself for `full`/`partial` scope.

### For `micro` scope

Skip agent delegation. Build the fix directly in this thread:
1. One short line confirming scope -- which file(s).
2. Build directly. No checklist dump, no agent hop.

---

## Step 5 -- Self-review

After the agent(s) return (or after a direct `micro` fix), apply `references/reviewer.md` to the output:
```
path/to/file.dart:line: CRITICAL: <problem>. <fix>.
path/to/file.dart:line: WARNING: <problem>. <fix>.
```
If clean: `Self-review: no violations found.`

---

## Step 6 -- Update skill memory

After task complete, append to `memory/` topic files (relative to this skill's folder):

| Category | Topic file |
|---|---|
| New endpoints/services | `memory/backend.md` |
| New screens/widgets | `memory/frontend.md` |
| Schema/migrations | `memory/schema.md` |
| Decisions & tradeoffs | `memory/decisions.md` |

Read the topic file first (may exist). Append, don't duplicate. Update `memory/MEMORY.md` index if a new file was added.
