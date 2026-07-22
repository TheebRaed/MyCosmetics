# MyCosmetics -- Claude Code Setup Package

This folder is a ready-to-drop-in Claude Code configuration for the **MyCosmetics** project (Serverpod backend + two Flutter apps). It was prepared separately from the actual codebase so it can be handed off and installed by whoever picks up the project.

## What's inside

```
mycosmetics-claude/
├── README.md              <- this file
├── CLAUDE.md               <- project-wide rules Claude reads automatically -- goes at the repo root
└── .claude/
    ├── agents/              <- 6 specialized subagents
    │   ├── mycosmetics-orchestrator.md   -- coordinates multi-layer features
    │   ├── mycosmetics-backend.md        -- Serverpod: protocol/repository/service/endpoint/migrations
    │   ├── mycosmetics-flutter.md        -- both Flutter apps (customer + admin)
    │   ├── mycosmetics-security.md       -- auth, sessions, permissions, payments, rate limiting, audit
    │   ├── mycosmetics-devops.md         -- Docker, Nginx, deployment, backups, monitoring
    │   └── mycosmetics-testing.md        -- Dart/Flutter tests
    └── skills/              <- 2 slash-command-style skills
        ├── mycosmetics-new-task/   -- run before starting any new feature/fix; loads context + delegates to agents
        └── mycosmetics-pr-review/  -- PR-style review of a branch against project standards
```

## How to install

1. Copy the **contents** of this folder into the root of the actual `mycosmetics` repo:
   - `CLAUDE.md` -> repo root (next to `docker-compose.prod.yml`, `docs/`, etc.)
   - `.claude/` -> repo root (merge if a `.claude/` folder already exists there)
2. Open Claude Code with the repo root as the working directory.
3. That's it -- Claude Code auto-loads `CLAUDE.md`, auto-discovers the agents in `.claude/agents/`, and the skills in `.claude/skills/` become available.

## How to use it day to day

- Starting a new feature or fix: just describe the task normally, or explicitly say "use mycosmetics-new-task" / invoke it as a skill. It figures out which app/layer is involved, loads the right docs, and either builds directly (small fixes) or delegates to the right `mycosmetics-*` agent(s).
- Reviewing a branch before merging: ask for a review of your branch/PR, or invoke `mycosmetics-pr-review` directly. It'll ask which base branch to diff against, then post line-by-line findings.
- You can also invoke any agent directly by name if you already know exactly which layer you're touching (e.g. "use mycosmetics-backend to add a new coupon type").

## Why this structure

This mirrors the pattern used on other multi-layer projects (a task-briefing skill that loads context and routes to a specialized agent fleet, plus a matching PR-review skill) but scoped entirely to this repo -- nothing here depends on any external, personal, or user-level Claude Code configuration. Everything the project needs ships inside `.claude/` and `CLAUDE.md`.

## Optional: generic Flutter/Dart know-how

This package intentionally does **not** bundle generic, non-project-specific community skills (e.g. `flutter-expert`, `mobile-developer`). They carry no MyCosmetics-specific knowledge -- everything load-bearing for this repo is already encoded in `mycosmetics-flutter.md` and `CLAUDE.md`. If whoever installs this wants general Flutter/Dart best-practice coverage on top, that's a personal (user-level, `~/.claude/skills/`) install choice, independent of this project package -- not something to commit into the repo.

## Extending it

- Found a recurring gotcha? Add it to `.claude/skills/mycosmetics-new-task/references/domain-traps.md`.
- Found a recurring review finding? Add a rule code to `.claude/skills/mycosmetics-pr-review/references/architecture-principles.md`.
- Need a 7th specialist (e.g. a dedicated BeautyTech/ML agent once that area matures)? Copy the shape of an existing file in `.claude/agents/` and add it -- then mention it in `CLAUDE.md`'s agent table and in `mycosmetics-orchestrator.md`'s execution-order sections.
