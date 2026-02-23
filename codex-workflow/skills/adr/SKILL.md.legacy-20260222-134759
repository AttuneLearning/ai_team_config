---
name: adr
description: Manage architecture decisions, gaps, and suggestions in dev_communication/shared/architecture.
---

# ADR Skill

Use this skill when the user asks to inspect architecture state, create suggestions, draft ADRs, or review ADR drift.

## Team-awareness

Read active team config from `.codex-workflow/config/active-team.json` when present.
Use team default paths (especially `architecture_root`) as the first lookup location.

## Actions

### 1. Status (default)

1. Read architecture hub/index files.
2. Count decisions, gaps, and pending suggestions.
3. Return concise status summary.

### 2. Check (full analysis)

1. Scan architecture decisions and logs.
2. Extract: ADR ID, title, status, and domain.
3. Cross-check against gap tracker.
4. Report missing/weakly-covered domains.

### 3. Gaps

1. Read gap index.
2. Summarize by priority and domain.
3. Recommend next ADRs to create.

### 4. Suggest

1. Gather topic, context, teams impacted, and priority.
2. Create suggestion in `dev_communication/shared/architecture/suggestions/`.
3. Filename: `YYYY-MM-DD_{team}_{topic_slug}.md`.

### 5. Poll

1. Scan team inboxes and active issues.
2. Detect architecture-significant changes.
3. Propose ADR suggestions where needed.

### 6. Create ADR

1. Gather ADR fields (or source from suggestion file).
2. Use ADR template from architecture templates.
3. Save ADR under `dev_communication/shared/architecture/decisions/`.
4. Update indexes/logs and mark linked suggestion/gap if addressed.

### 7. Review ADR

1. Read target ADR.
2. Check for staleness and implementation drift.
3. Propose updates; apply on user approval.

## Output expectations

- Include exact file paths touched.
- Separate observations from recommendations.
- Keep summaries short unless the user requests deep analysis.
