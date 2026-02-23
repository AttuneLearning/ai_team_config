---
name: context
description: Load relevant ADRs, patterns, and memory before implementation work.
---

# Context Skill

Use this skill before implementation to reduce rework and align with existing decisions.

## Team-awareness

Read active team config from `.codex-workflow/config/active-team.json` when present.
Use its `architecture_root` and `memory_root` to locate context sources.

## Modes

### Quick mode

Use when the user asks for a fast orientation.

1. Read `<memory_root>/memory-log.md`.
2. Read project overview context file(s).
3. If a topic is provided, search memory for topic keywords.
4. Return a short "recent activity + relevant references" summary.

### Full mode (default)

1. Infer work type from request:
   - `new-endpoint`, `new-model`, `bug-fix`, `auth-change`, `testing`
2. Load relevant ADR summaries (limit to most relevant).
3. Load relevant patterns for the inferred work type.
4. Load related entity/context notes from memory.
5. Return:
   - work-type summary
   - relevant ADRs
   - relevant patterns
   - checklist for implementation

## Token discipline

- Prioritize summaries over long excerpts.
- Limit loaded references to what is necessary for the task at hand.
