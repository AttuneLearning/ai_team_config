# Team Configs

Reusable team configuration files shared across repos via the `.claude-workflow` submodule.

## Active Configs

| File | Purpose | Model |
|------|---------|-------|
| `code-reviewer-config.json` | QA/Architect code gate for completion workflow | Opus 4.6 |
| `agent-team-roles.json` | Agent team role definitions (lead, implementer, tester, researcher) | Opus 4.6 lead + Sonnet 4.5 teammates |
| `agent-team-hooks-guide.md` | Hook setup documentation for agent team quality gates | N/A (docs) |

## Override Strategy

The configs in this directory are **frontend defaults** (FSD, Vitest, React Testing Library). Backend or non-frontend projects should create local overrides:

```
your-project/.claude/team-configs/
├── agent-team-roles.json       # Override: swap FSD → your architecture, Vitest → your test runner
└── code-reviewer-config.json   # Override: swap FSD checks → your layer checks, test commands
```

**What to override** in a backend project:
- `teamStructure.teammates.implementer` — architecture pattern, spawn prompt
- `teamStructure.teammates.tester` — test framework, context files, spawn prompt
- `teamStructure.teammates.researcher` — architecture terminology
- `teamPresets.*.selectWhen` — layer terminology (FSD → your layers)
- `gateApproval.criteria.mandatory` — test commands (`vitest` → `jest`, etc.)
- `reviewChecklist` — framework-specific checks
- `automatedChecks.commands` — test/coverage commands

**What stays the same** across all projects:
- `teamStructure.lead` — role, model, responsibilities
- `teamPresets` — preset names and structure
- `teamSelection`, `midDevReview`, `postDevReview` — workflow phases
- `taskDependencyPatterns` — flow patterns
- `coordinationRules` — team coordination
- `memoryProtocol` — session/pattern file structure
- `gateApproval` structure — just swap the commands

## Project-Level Files (`.claude/`)

These files live in each project repo (not in the submodule) because they contain project-specific paths or settings:

| File | Purpose | Notes |
|------|---------|-------|
| `settings.json` | Project settings: permissions, plugins, env, hooks | Enables agent teams + hook wiring |
| `hooks/task-completed.sh` | TaskCompleted quality gate hook | Portable via team detection from cwd |
| `hooks/teammate-idle.sh` | TeammateIdle quality gate hook | Portable via team detection from cwd |
| `team-configs/*.json` | Local overrides of submodule configs | Only needed for non-frontend projects |
| `commands/` | Symlinks to `.claude-workflow/skills/` | Connects submodule skills to project |

## Learned Team Configs (`memory/team-configs/`)

Project-specific directory storing team compositions learned from post-dev reviews:

| File | Purpose |
|------|---------|
| `_template.json` | Template for new learned config entries |
| `{issue-type}--{qualifier}.json` | Learned configs (one per significant review) |
| `index.md` | Directory overview and lookup strategy |

Team selection reads these to match past effective configs to new issues.
Post-dev review promotes successful configs here when effectiveness is "excellent" or "good".

## Legacy Files (`.claude/archive/`)

Older team configs archived from `.claude/`. Superseded by the agent team roles + preset system:

| File | Status |
|------|--------|
| `team-config.json` | Superseded by agent-team-roles.json |
| `team-config.backup.json` | Archived |
| `team-config.old.json` | Archived |
| `team-config-ui-auth.json` | Archived (covered by presets) |
| `team-config-learning-unit-ui.json` | Archived (covered by presets) |
| `bug-fix-team-config.json` | Archived (covered by bugFix pattern) |
